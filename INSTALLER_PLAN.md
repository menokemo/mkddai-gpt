# Installer Plan

## v3 Installer

File:

```text
install_ai_factory_v3_no_litellm.sh
```

## Changes

Removed:

- LiteLLM service
- LiteLLM environment variables
- Open WebUI -> LiteLLM wiring

Added:

- PostgreSQL schema init for AI Factory memory
- n8n AI-ready stack
- OpenHands direct OpenRouter instructions

## Services

```text
postgres
redis
searxng
n8n
open-webui
openhands
```

## After Install

1. Open n8n.
2. Create OpenRouter credential.
3. Build AI Agent workflow manually.
4. Open OpenHands and set OpenRouter direct.
5. Add Open WebUI Pipe to n8n webhook.
