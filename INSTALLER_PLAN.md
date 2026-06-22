# Installer Plan

## Final Installer

File:

```text
install_ai_factory_v3.sh
```

## What it installs

- Docker
- PostgreSQL
- Redis
- SearXNG
- n8n
- Open WebUI
- OpenHands

## What it removes from final design

- LiteLLM

## Database Schema

The installer automatically creates:

```text
ai_projects
ai_conversations
ai_messages
ai_project_memory
ai_agent_runs
ai_tasks
ai_qa_reports
ai_research_reports
ai_builder_temporary_workflow
n8n_chat_histories
```

## Re-apply schema

The installer also creates:

```text
/opt/ai-factory/scripts/apply_schema.sh
```

Use:

```bash
cd /opt/ai-factory
sudo bash scripts/apply_schema.sh
```

## OpenWebUI Pipe

The installer writes:

```text
/opt/ai-factory/docs/openwebui_ai_factory_pipe.py
```

This pipe filters OpenWebUI internal prompts such as title generation, tag generation, and follow-up suggestions so they do not pollute n8n memory.
