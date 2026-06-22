# Open WebUI Setup

## Role

Open WebUI is the user interface.

It sends requests to n8n.

## Webhook

Use:

```text
http://192.168.2.29:5678/webhook/ai-factory-v3
```

## Payload

```json
{
  "message": "اعمل منصة SaaS لإدارة العيادات",
  "chat_title": "Open WebUI Project"
}
```

## Important

Do not use old v2.1 webhook:

```text
/webhook/ai-factory-v21
```

## Current Status

Open WebUI -> n8n -> AI Agent -> OpenRouter -> Respond works.
