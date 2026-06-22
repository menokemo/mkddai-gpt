# Bootstrap Notes

The final installer is:

```text
install_ai_factory_v3.sh
```

It should be committed to the repository.

It installs:

- PostgreSQL
- Redis
- SearXNG
- n8n
- Open WebUI
- OpenHands

It does not install LiteLLM.

It creates all required PostgreSQL tables.

It creates:

```text
/opt/ai-factory/scripts/apply_schema.sh
```

for future safe schema re-application.
