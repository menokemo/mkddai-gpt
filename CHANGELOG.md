# Changelog

## 2026-06-22

### Major v3 Decision

LiteLLM removed from final script.

### Current Architecture

- n8n uses OpenRouter Chat Model directly.
- OpenHands uses OpenRouter directly.
- PostgreSQL stays and becomes memory database.
- Open WebUI sends to n8n webhook.

### Working Test

Webhook `/webhook/ai-factory-v3` works.

Classifier Agent successfully classified:

```text
اعمل منصة SaaS لإدارة العيادات
```

as requiring UI, backend, database, no mobile app unless requested, no AI unless requested, and medium-to-high complexity.
