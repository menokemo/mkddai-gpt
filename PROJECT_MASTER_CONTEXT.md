# MKDD AI Factory - Project Master Context

This file is the main context file for continuing the MKDD AI Factory project in any future chat.

## Project Goal

Build a self-hosted AI software company system where the user talks to an intelligent technical General Manager through Open WebUI. The General Manager discusses ideas, asks questions, researches when needed, and launches specialized AI employees to plan, build, review, and deliver software projects.

## Final Architecture Direction

```text
Open WebUI
  -> n8n Webhook
  -> 00_AI_General_Manager
  -> 02_Intent_Analyzer
  -> Switch / Router
      -> Chat / Direct Reply
      -> Research
      -> New Project
      -> Continue Project
  -> Specialized AI Employees
  -> PostgreSQL Memory
  -> GitHub
  -> OpenHands
  -> QA / Delivery
```

## Final Stack

- Open WebUI: user-facing chat interface.
- n8n: workflow orchestration.
- OpenRouter: model provider directly used by n8n AI Agent Chat Model nodes.
- PostgreSQL: persistent memory, projects, tasks, QA, research, and chat histories.
- GitHub: source of truth for project docs, code, decisions, and delivery.
- OpenHands: coding executor only.
- SearXNG: search/research service.
- Redis: support/cache service.
- LiteLLM: removed from final stack.

## Key Decisions

1. LiteLLM is removed from the final bootstrap script.
2. n8n AI Agent nodes are used for employees.
3. No Code / Function / Python / JavaScript nodes inside n8n.
4. OpenHands uses OpenRouter directly.
5. n8n uses OpenRouter Chat Model directly.
6. The first user-facing AI employee is `00_AI_General_Manager`.
7. The General Manager must remain conversational and smart, not a parser.
8. Intent analysis is handled by a hidden node after the General Manager.
9. PostgreSQL is mandatory and the installer must create all tables automatically.
10. OpenWebUI internal prompts must be filtered by the Pipe so they do not pollute memory.
11. GitHub is the durable source of truth for docs and project state.

## Current Working State

Confirmed working:

- Open WebUI sends to n8n webhook.
- n8n webhook `/webhook/ai-factory-v3` works.
- `00_AI_General_Manager` responds through OpenRouter Chat Model.
- PostgreSQL is running.
- PostgreSQL tables were created.
- Postgres Chat Memory works.
- OpenWebUI Pipe was fixed to filter internal prompts:
  - title generation
  - tags
  - follow-up suggestions
- General Manager can remember context after filtering OpenWebUI internal prompts.

## Current Important Tables

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

## Current Important Scripts

Final bootstrap package:

```text
install_ai_factory_v3.sh
```

It must:
- install Docker if missing
- create folders
- create `.env`
- start PostgreSQL, Redis, SearXNG, n8n, Open WebUI, OpenHands
- create all PostgreSQL tables automatically
- create `scripts/apply_schema.sh`
- create OpenWebUI Pipe file in `docs/openwebui_ai_factory_pipe.py`

## OpenWebUI Pipe Notes

Current version:

```text
1.0.3
```

It sends:

```json
{
  "message": "real user message",
  "chat_title": "chat title or id",
  "chat_id": "chat/session id"
}
```

It filters internal prompts starting with:

```text
### Task:
Generate a concise
Generate 1-3 broad tags
Suggest 3-5 relevant follow-up
```

## n8n Memory Notes

Temporary memory session key used during testing:

```text
mkddai-main-chat
```

Next improvement:

Use real OpenWebUI `chat_id` as session key:

```text
{{ $json.chat_id }}
```

This avoids all users/chats sharing one memory.

## Next Major Build Phase

Build:

```text
02_Intent_Analyzer
```

Purpose:

Classify the conversation path after the General Manager.

Possible outputs:

```text
CHAT
PROJECT
RESEARCH
TECH_SUPPORT
BUSINESS
CONTINUE_PROJECT
```

Then add a Switch node.

## Immediate Next Steps

1. Update n8n Memory Session Key to use `chat_id` instead of fixed `mkddai-main-chat`.
2. Build `02_Intent_Analyzer`.
3. Build Switch Router.
4. Create research path using SearXNG.
5. Create new project path:
   - Save project in `ai_projects`
   - PM Agent
   - Product Analyst
   - UI/Backend/Database planners
6. Add GitHub Manager.
7. Add OpenHands Executor.
8. Add QA and Revision loop.
9. Add Delivery Manager.
10. Add Memory Manager.

## How to Resume in a New Chat

Tell the assistant:

```text
This is the MKDD AI Factory project. Read PROJECT_MASTER_CONTEXT.md, CURRENT_STATUS.md, NEXT_STEPS.md, and DECISIONS_LOG.md, then continue from the latest step.
```
