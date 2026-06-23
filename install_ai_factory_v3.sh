#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${APP_DIR:-/opt/ai-factory}"

echo "== MKDD AI Factory v3 Bootstrap =="
echo "Stack: Open WebUI + n8n + PostgreSQL + OpenHands + SearXNG + Redis"
echo "Removed: LiteLLM"
echo

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo bash install_ai_factory_v3.sh"
  exit 1
fi

apt-get update -y
apt-get install -y ca-certificates curl gnupg git openssl unzip

if ! command -v docker >/dev/null 2>&1; then
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

mkdir -p "$APP_DIR"/{n8n,postgres,openwebui,openhands,projects,searxng,redis,backups,docs,db-init,scripts}
cd "$APP_DIR"

if [[ ! -f "$APP_DIR/.env" ]]; then
cat > "$APP_DIR/.env" <<EOF
POSTGRES_USER=n8n
POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -d '\n')
POSTGRES_DB=n8n

N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 18 | tr -d '\n')
N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)

OPENWEBUI_SECRET_KEY=$(openssl rand -hex 32)
OPENHANDS_BASE_URL=http://openhands:3000
SEARXNG_BASE_URL=http://searxng:8080

# Shared secret the OpenWebUI Pipe sends in a header so the n8n webhook can
# reject requests that don't come from our own Pipe. Copy this value into
# the Pipe's webhook_secret field (see README-FIRST.md).
AI_FACTORY_WEBHOOK_SECRET=$(openssl rand -hex 24 | tr -d '\n')
EOF
fi

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

CREATE TABLE IF NOT EXISTS ai_conversations (
    id BIGSERIAL PRIMARY KEY,
    conversation_key TEXT UNIQUE NOT NULL,
    title TEXT,
    status TEXT DEFAULT 'active',
    current_project_id BIGINT REFERENCES ai_projects(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_messages (
    id BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    intent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
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

CREATE TABLE IF NOT EXISTS ai_research_reports (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES ai_projects(id) ON DELETE SET NULL,
    query TEXT,
    findings TEXT,
    recommendations TEXT,
    sources TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Design Variants Gate: each row is one page of one design variant (A/B)
-- for one platform (web/app). The client previews these as real HTML and
-- picks a variant before any execution spend.
CREATE TABLE IF NOT EXISTS ai_design_variants (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES ai_projects(id) ON DELETE CASCADE,
    platform TEXT NOT NULL,        -- 'web' | 'app'
    variant_label TEXT NOT NULL,   -- 'A' | 'B'
    page_slug TEXT NOT NULL,       -- 'home' | 'products' | 'product-detail' | ...
    html_content TEXT NOT NULL,
    chosen BOOLEAN,                -- NULL until the client decides
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cost Dashboard: one row per agent call, so cost can be broken down per
-- project, per agent (employee), and per model. OpenRouter returns cost in
-- USD automatically in every response.
CREATE TABLE IF NOT EXISTS ai_token_usage (
    id BIGSERIAL PRIMARY KEY,
    project_id BIGINT REFERENCES ai_projects(id) ON DELETE CASCADE,
    agent_name TEXT NOT NULL,
    model_name TEXT NOT NULL,
    prompt_tokens INT,
    completion_tokens INT,
    cost_usd NUMERIC(10,6),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS n8n_chat_histories (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    message JSONB NOT NULL
);

-- Added so every agent can compute the real time gap since the user's last
-- message (per-turn, not just at session start) instead of guessing from
-- conversational patterns. Safe to add to an existing table: n8n's own
-- inserts don't reference this column, so it's filled by the DEFAULT.
ALTER TABLE n8n_chat_histories ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

CREATE TABLE IF NOT EXISTS ai_builder_temporary_workflow (
    id BIGSERIAL PRIMARY KEY,
    name TEXT,
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_projects_slug ON ai_projects(project_slug);
CREATE INDEX IF NOT EXISTS idx_ai_projects_status ON ai_projects(status);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_key ON ai_conversations(conversation_key);
CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation_id ON ai_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_tasks_project_id ON ai_tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_ai_agent_runs_project_id ON ai_agent_runs(project_id);
CREATE INDEX IF NOT EXISTS idx_n8n_chat_histories_session_id ON n8n_chat_histories(session_id);
CREATE INDEX IF NOT EXISTS idx_n8n_chat_histories_session_created ON n8n_chat_histories(session_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_design_variants_project_id ON ai_design_variants(project_id);
CREATE INDEX IF NOT EXISTS idx_ai_token_usage_project_id ON ai_token_usage(project_id);
EOF

cat > "$APP_DIR/scripts/apply_schema.sh" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
APP_DIR="${APP_DIR:-/opt/ai-factory}"
cd "$APP_DIR"
set -a
source "$APP_DIR/.env"
set +a
docker exec -i ai-factory-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$APP_DIR/db-init/01-ai-factory-schema.sql"
echo "Schema applied."
EOF
chmod +x "$APP_DIR/scripts/apply_schema.sh"

if [[ ! -f "$APP_DIR/searxng/settings.yml" ]]; then
cat > "$APP_DIR/searxng/settings.yml" <<EOF
# Read the documentation before extending the defaults:
# https://docs.searxng.org/admin/settings/
use_default_settings: true
server:
  secret_key: "$(openssl rand -hex 16)"
  image_proxy: true
search:
  formats:
    - html
    - json
EOF
fi

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
      - redis
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
      WEBHOOK_URL: http://localhost:5678/
      OPENHANDS_BASE_URL: ${OPENHANDS_BASE_URL}
      SEARXNG_BASE_URL: ${SEARXNG_BASE_URL}
      AI_FACTORY_WEBHOOK_SECRET: ${AI_FACTORY_WEBHOOK_SECRET}
      N8N_AI_ENABLED: "true"
      GENERIC_TIMEZONE: "Africa/Cairo"
      TZ: "Africa/Cairo"
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

cat > "$APP_DIR/docs/openwebui_ai_factory_pipe.py" <<'EOF'
"""
title: AI Factory
author: MKDD
version: 1.0.4
description: Send real user project requests from Open WebUI to n8n AI Factory workflow.
requirements: requests
"""

import requests


class Pipe:
    def __init__(self):
        self.name = "AI Factory"
        self.webhook_url = "http://YOUR_SERVER_IP:5678/webhook/ai-factory-v3"
        # Copy the AI_FACTORY_WEBHOOK_SECRET value printed at the end of the
        # installer (also saved in /opt/ai-factory/.env) into this field.
        self.webhook_secret = "YOUR_WEBHOOK_SECRET"

    async def pipe(self, body: dict) -> str:
        messages = body.get("messages", [])
        user_message = ""

        if messages:
            user_message = messages[-1].get("content", "") or ""

        user_message = user_message.strip()

        internal_prefixes = [
            "### Task:",
            "Generate a concise",
            "Generate 1-3 broad tags",
            "Suggest 3-5 relevant follow-up",
        ]

        if any(user_message.startswith(prefix) for prefix in internal_prefixes):
            return ""

        if not user_message:
            return ""

        chat_id = body.get("chat_id") or body.get("id") or "default"

        payload = {
            "message": user_message,
            "chat_title": body.get("title") or body.get("chat_id") or "Open WebUI Project",
            "chat_id": chat_id,
        }

        try:
            response = requests.post(
                self.webhook_url,
                json=payload,
                headers={"X-AI-Factory-Secret": self.webhook_secret},
                timeout=900,
            )
            response.raise_for_status()

            try:
                data = response.json()
            except Exception:
                return response.text

            if isinstance(data, dict):
                return data.get("reply") or data.get("output") or str(data)

            return str(data)

        except Exception as e:
            return f"AI Factory error: {e}"
EOF

cat > "$APP_DIR/README-FIRST.md" <<'EOF'
# MKDD AI Factory v3

Final stack without LiteLLM.

## URLs

- Open WebUI: http://YOUR_SERVER_IP:8080
- n8n: http://YOUR_SERVER_IP:5678
- OpenHands: http://YOUR_SERVER_IP:3000
- SearXNG: http://YOUR_SERVER_IP:8081

## Database schema

The installer creates all AI Factory tables automatically.

To re-apply schema safely:

```bash
cd /opt/ai-factory
sudo bash scripts/apply_schema.sh
```

## OpenWebUI Pipe

Copy `/opt/ai-factory/docs/openwebui_ai_factory_pipe.py` into Open WebUI Functions/Pipes.

Replace `YOUR_SERVER_IP` and `YOUR_WEBHOOK_SECRET` (the real secret value is in `/opt/ai-factory/.env` as `AI_FACTORY_WEBHOOK_SECRET`, and is also printed at the end of this installer).

The n8n workflow's webhook-security check (an IF node comparing the `X-AI-Factory-Secret` header against this value) is built separately, node by node, inside n8n itself — not by this installer.
EOF

chown -R 1000:1000 "$APP_DIR/n8n" || true

docker compose pull
docker compose up -d

sleep 5
set -a
source "$APP_DIR/.env"
set +a
docker exec -i ai-factory-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$APP_DIR/db-init/01-ai-factory-schema.sql" || true

echo "== Done =="
echo "Open WebUI: http://YOUR_SERVER_IP:8080"
echo "n8n:        http://YOUR_SERVER_IP:5678"
echo "OpenHands:  http://YOUR_SERVER_IP:3000"
echo "SearXNG:    http://YOUR_SERVER_IP:8081"
echo
echo "AI_FACTORY_WEBHOOK_SECRET (copy this into the OpenWebUI Pipe's webhook_secret field):"
echo "${AI_FACTORY_WEBHOOK_SECRET}"
