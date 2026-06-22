# MKDD AI Factory v3

MKDD AI Factory v3 is a self-hosted AI software-production system.

This version removes LiteLLM and uses OpenRouter directly from n8n AI Agent nodes and OpenHands.

## Final v3 Stack

```text
Open WebUI
  -> n8n Webhook
  -> n8n AI Agent Employees
  -> OpenRouter Chat Models
  -> PostgreSQL Memory
  -> GitHub
  -> OpenHands
  -> QA / Delivery
  -> Open WebUI Response
```

## Removed From v3

- LiteLLM service
- LiteLLM folder
- LiteLLM master key
- LiteLLM model gateway
- Open WebUI -> LiteLLM connection
- HTTP/JSON employee workflow

## Kept / Added

- Open WebUI
- n8n
- OpenHands
- OpenRouter
- PostgreSQL
- GitHub
- SearXNG
- Redis
- n8n AI Agent nodes
- IF / Switch / Merge workflow logic
- PostgreSQL memory plan

## Core Rule

The workflow must be built with n8n visual nodes, not code.

Avoid:

- Code nodes
- Function nodes
- JavaScript
- Python
- Raw employee JSON bodies

Use:

- AI Agent nodes
- OpenRouter Chat Model nodes
- IF / Switch nodes
- Merge nodes
- Edit Fields nodes
- PostgreSQL nodes
- GitHub nodes
- Respond to Webhook
- HTTP Request only for OpenHands service calls
