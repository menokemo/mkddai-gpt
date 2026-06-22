# MKDD AI Factory v3

MKDD AI Factory v3 is a self-hosted AI software-company system.

## Current Final Direction

- No LiteLLM in the final stack.
- n8n is the workflow/orchestration layer.
- Open WebUI is the user interface.
- OpenRouter is used directly by n8n AI Agent Chat Model nodes.
- OpenHands uses OpenRouter directly.
- PostgreSQL stores memory, projects, tasks, QA, research, and chat history.
- SearXNG is available for research.
- Redis is used as support/cache service.

## Final Stack

```text
Open WebUI
  -> n8n Webhook
  -> 00_AI_General_Manager
  -> Intent Analyzer / Router
  -> Specialized AI Employees
  -> PostgreSQL Memory
  -> GitHub
  -> OpenHands
  -> QA / Delivery
```

## Important Installer

Use:

```text
install_ai_factory_v3.sh
```

The installer now creates the required PostgreSQL tables automatically.
