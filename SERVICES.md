# Services

## Final v3 Services

```text
postgres
redis
searxng
n8n
open-webui
openhands
```

## Removed

```text
litellm
```

## Ports

```text
Open WebUI: 8080
n8n: 5678
OpenHands: 3000
SearXNG: 8081
PostgreSQL: internal
Redis: internal
```

## Folder Layout

Expected folder under `/opt/ai-factory`:

```text
docker-compose.yml
.env
n8n/
postgres/
openwebui/
openhands/
projects/
searxng/
redis/
db-init/
backups/
docs/
README-FIRST.md
```

## Useful Commands

```bash
cd /opt/ai-factory
sudo docker compose ps
sudo docker logs ai-factory-n8n --tail=100
sudo docker logs ai-factory-openhands --tail=100
sudo docker logs ai-factory-open-webui --tail=100
```
