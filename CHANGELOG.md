# Changelog

## 2026-06-23

### Installer updated

- Final bootstrap script now creates all PostgreSQL tables automatically.
- Added `scripts/apply_schema.sh`.
- Added OpenWebUI Pipe v1.0.3.
- Removed LiteLLM from final installer.
- Added `ai_research_reports`.
- Added `n8n_chat_histories` creation fallback.

### Memory issue diagnosed

OpenWebUI was sending internal title/tag/follow-up prompts into n8n memory.

Fix:
- Pipe v1.0.3 filters internal prompts.
- Memory is now cleaner and the General Manager can recall user-provided context better.
