#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/opt/ai-factory"

echo "== MKDD AI Factory v3 Installer =="
echo "Stack: Open WebUI, n8n, PostgreSQL, OpenHands, SearXNG, Redis"
echo "Removed: LiteLLM"
echo "Models: n8n AI Agents use OpenRouter Chat Model directly from n8n credentials."
echo "OpenHands: use OpenRouter directly from OpenHands UI."
echo

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo:"
  echo "  sudo bash install_ai_factory_v3_no_litellm.sh"
  exit 1
fi

apt-get update -y
apt-get install -y ca-certificates curl gnupg git openssl unzip

if ! command -v docker >/dev/null 2>&1; then
  echo "== Installing Docker =="
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

systemctl enable docker
systemctl start docker

echo "== Creating folders =="
mkdir -p "$APP_DIR"/{n8n,postgres,openwebui,openhands,projects,searxng,redis,backups,docs,db-init}
cd "$APP_DIR"

if [[ ! -f "$APP_DIR/.env" ]]; then
  echo "== Creating .env =="
  cat > "$APP_DIR/.env" <<EOF
# MKDD AI Factory v3
# Do not commit this file.

POSTGRES_USER=mkddai
POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -d '\n')
POSTGRES_DB=mkddai_factory

N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 18 | tr -d '\n')
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

OPENWEBUI_SECRET_KEY=$(openssl rand -hex 32)

OPENHANDS_BASE_URL=http://openhands:3000
SEARXNG_BASE_URL=http://searxng:8080

# OpenRouter keys are NOT stored here by default.
# Add them inside n8n Credentials and OpenHands UI.
EOF
else
  echo "== Existing .env found; keeping it =="
  grep -q '^N8N_ENCRYPTION_KEY=' "$APP_DIR/.env" || echo "N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)" >> "$APP_DIR/.env"
  grep -q '^OPENWEBUI_SECRET_KEY=' "$APP_DIR/.env" || echo "OPENWEBUI_SECRET_KEY=$(openssl rand -hex 32)" >> "$APP_DIR/.env"
fi

echo "== Writing PostgreSQL init schema =="
cat > "$APP_DIR/db-init/01-ai-factory-schema.sql" <<'EOF'
CREATE TABLE IF NOT EXISTS ai_projects (
    id BIGSERIAL PRIMARY KEY,
    project_slug TEXT UNIQUE NOT NULL,
    title TEXT,
    status TEXT DEFAULT 'new',
    repo_url TEXT,
    branch_name TEXT,
    project_type TEXT,
    needs_ui BOOLEAN DEFAULT FALSE,
    needs_backend BOOLEAN DEFAULT FALSE,
    needs_database BOOLEAN DEFAULT FALSE,
    needs_mobile_app BOOLEAN DEFAULT FALSE,
    needs_ai BOOLEAN DEFAULT FALSE,
    complexity TEXT,
    summary TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_project_memory (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES ai_projects(id) ON DELETE CASCADE,
    summary TEXT,
    decisions TEXT,
    next_action TEXT,
    open_risks TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_agent_runs (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES ai_projects(id) ON DELETE SET NULL,
    agent_name TEXT NOT NULL,
    input_summary TEXT,
    output_summary TEXT,
    status TEXT DEFAULT 'completed',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_tasks (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES ai_projects(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    owner_agent TEXT,
    status TEXT DEFAULT 'todo',
    priority TEXT DEFAULT 'normal',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_qa_reports (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES ai_projects(id) ON DELETE CASCADE,
    qa_status TEXT,
    report TEXT,
    revision_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
EOF

echo "== Writing docker-compose.yml =="
cat > "$APP_DIR/docker-compose.yml" <<'EOF'
services:
  postgres:
    image: postgres:16-alpine
    container_name: ai-factory-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./postgres:/var/lib/postgresql/data
      - ./db-init:/docker-entrypoint-initdb.d:ro
    networks:
      - ai-factory
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 10

  redis:
    image: redis:7-alpine
    container_name: ai-factory-redis
    restart: unless-stopped
    command: redis-server --save "" --appendonly no
    volumes:
      - ./redis:/data
    networks:
      - ai-factory
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 10

  searxng:
    image: searxng/searxng:latest
    container_name: ai-factory-searxng
    restart: unless-stopped
    ports:
      - "8081:8080"
    environment:
      SEARXNG_BASE_URL: http://localhost:8081/
      SEARXNG_REDIS_URL: redis://redis:6379/0
    volumes:
      - ./searxng:/etc/searxng
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - ai-factory

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: ai-factory-n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_PORT: 5432
      DB_POSTGRESDB_DATABASE: ${POSTGRES_DB}
      DB_POSTGRESDB_USER: ${POSTGRES_USER}
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_PASSWORD}

      N8N_HOST: ${N8N_HOST}
      N8N_PORT: ${N8N_PORT}
      N8N_PROTOCOL: ${N8N_PROTOCOL}
      N8N_SECURE_COOKIE: "false"
      N8N_BASIC_AUTH_ACTIVE: "true"
      N8N_BASIC_AUTH_USER: ${N8N_BASIC_AUTH_USER}
      N8N_BASIC_AUTH_PASSWORD: ${N8N_BASIC_AUTH_PASSWORD}
      N8N_ENCRYPTION_KEY: ${N8N_ENCRYPTION_KEY}

      # Needed because Open WebUI and local testing use webhook URLs.
      WEBHOOK_URL: http://localhost:5678/

      # Internal service URLs available for future n8n nodes.
      OPENHANDS_BASE_URL: ${OPENHANDS_BASE_URL}
      SEARXNG_BASE_URL: ${SEARXNG_BASE_URL}

      # n8n AI features
      N8N_AI_ENABLED: "true"
    volumes:
      - ./n8n:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
      openhands:
        condition: service_started
      searxng:
        condition: service_started
    networks:
      - ai-factory

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: ai-factory-open-webui
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      WEBUI_SECRET_KEY: ${OPENWEBUI_SECRET_KEY}

      # No LiteLLM in v3.
      # Open WebUI can use its own provider settings, and AI Factory Pipe calls n8n directly.
      ENABLE_SIGNUP: "true"
    volumes:
      - ./openwebui:/app/backend/data
    networks:
      - ai-factory

  openhands:
    image: ghcr.io/openhands/openhands:1.8.0
    container_name: ai-factory-openhands
    restart: unless-stopped
    ports:
      - "3000:3000"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    environment:
      SANDBOX_ADD_HOSTS: "host.docker.internal:host-gateway"
      LOG_ALL_EVENTS: "true"
      WORKSPACE_BASE: /opt/workspace_base
      # Configure LLM from OpenHands UI:
      # Base URL: https://openrouter.ai/api/v1
      # API Key: OpenRouter key
      # Model: openrouter/qwen/qwen3-coder-plus or another working model
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./openhands:/.openhands
      - ./projects:/opt/workspace_base
    networks:
      - ai-factory

networks:
  ai-factory:
    name: ai-factory
EOF

echo "== Writing README-FIRST.md =="
cat > "$APP_DIR/README-FIRST.md" <<'EOF'
# MKDD AI Factory v3

This version removes LiteLLM.

## Services

- Open WebUI: http://YOUR_SERVER_IP:8080
- n8n: http://YOUR_SERVER_IP:5678
- OpenHands: http://YOUR_SERVER_IP:3000
- SearXNG: http://YOUR_SERVER_IP:8081
- PostgreSQL: internal

## Credentials

```bash
sudo cat /opt/ai-factory/.env
```

## Model Setup

### n8n

Use n8n AI Agent nodes with OpenRouter Chat Model directly.

Create OpenRouter credentials inside n8n.

### OpenHands

Configure OpenHands directly:

```text
Base URL: https://openrouter.ai/api/v1
API Key: your OpenRouter key
Model: openrouter/qwen/qwen3-coder-plus
```

### Open WebUI

Open WebUI sends user requests to n8n through a Pipe/Function.

Use webhook:

```text
http://YOUR_SERVER_IP:5678/webhook/ai-factory-v3
```

## Docker

Use sudo unless your user is in the docker group:

```bash
cd /opt/ai-factory
sudo docker compose ps
sudo docker logs ai-factory-n8n --tail=100
```
EOF

# n8n container user normally UID/GID 1000.
chown -R 1000:1000 "$APP_DIR/n8n"

echo "== Pulling images =="
docker compose pull

echo "== Starting stack =="
docker compose up -d

echo
echo "== Done =="
echo "LiteLLM has been removed from this v3 stack."
echo
echo "Open WebUI: http://YOUR_SERVER_IP:8080"
echo "n8n:        http://YOUR_SERVER_IP:5678"
echo "OpenHands:  http://YOUR_SERVER_IP:3000"
echo "SearXNG:    http://YOUR_SERVER_IP:8081"
echo
echo "Credentials:"
echo "  sudo cat $APP_DIR/.env"
echo
echo "Check services:"
echo "  cd $APP_DIR && sudo docker compose ps"
