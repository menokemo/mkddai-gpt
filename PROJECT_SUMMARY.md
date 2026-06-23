# Project Summary

A living summary of **MKDD AI Factory v3**: what the project is, every idea/feature that was discussed, whether it was built or postponed, and why. Update this file whenever scope, features, or status change — so anyone new joining the project can read this and understand where things stand without re-reading the whole chat history.

## What this project is

A self-hosted AI software-company system. The user talks to an intelligent technical General Manager through Open WebUI. The General Manager discusses ideas, asks questions, researches when needed, and launches specialized AI employees to plan, build, review, and deliver software projects.

## Final stack (current direction)

```text
Open WebUI  -> n8n Webhook -> 00_AI_General_Manager -> Intent Analyzer / Router
  -> Specialized AI Employees -> PostgreSQL Memory -> GitHub -> OpenHands -> QA / Delivery
```

- **Open WebUI** — user-facing chat interface.
- **n8n** — main orchestration engine (routing, employees, memory, GitHub, OpenHands, QA).
- **OpenRouter** — model provider, used directly by n8n AI Agent nodes and by OpenHands.
- **PostgreSQL** — persistent memory: projects, tasks, QA, research, chat history.
- **GitHub** — source of truth for docs, decisions, code, and delivery.
- **OpenHands** — coding executor only (receives strict execution briefs).
- **SearXNG** — research/search service.
- **Redis** — support/cache service.

## Features & ideas — status tracker

### ✅ Done
| Feature | Notes |
|---|---|
| `00_AI_General_Manager` | User-facing conversational AI layer. Must stay conversational, not a parser. |
| Postgres Chat Memory | Working, stores conversation memory. |
| OpenWebUI Pipe internal-prompt filtering (v1.0.3) | Fixes memory pollution from title/tag/follow-up system prompts — see `BUGS_AND_FIXES.md`. |
| Automatic PostgreSQL table creation | Installer (`install_ai_factory_v3.sh`) creates all required tables on setup. |
| Core Docker stack | PostgreSQL, Redis, SearXNG, n8n, Open WebUI, OpenHands all running. |
| Dynamic memory session key | Changed from fixed `mkddai-main-chat` to `{{ $json.body.chat_id }}` so each chat gets isolated memory. Pending live confirmation — see `BUGS_AND_FIXES.md`. |
| Intent Analyzer (`01B_Intent_Analyzer`) | Classifies into `CHAT` / `ASK_CLARIFICATION` / `RESEARCH` / `NEW_PROJECT` / `CONTINUE_PROJECT`. Fixed to receive the real user message, not just the GM's reply. |
| Switch Router (`01C_Intent_Router`) | Drafted in `workflows/ai-factory-v3.json` but **superseded** — see Rejected table. Not part of the live design. |
| Web search Tool on General Manager | n8n native SearXNG tool node attached to `00_AI_General_Manager`'s `ai_tool` input. Model decides when to search. Installer now enables SearXNG JSON format automatically. |

### ⏳ Planned / not built yet
| Feature | Idea | Why / Reasoning | Status |
|---|---|---|---|
| New Project path | Save Project → PM Agent → Product Analyst → Architect | Core flow for handling new software project requests | Not built |
| GitHub Manager | Node/agent that manages reading/writing project repos | Needed before OpenHands execution can happen on real repos | Not built |
| OpenHands Executor integration | Wire n8n execution briefs into OpenHands | Actual code-writing step of the pipeline | Not built |
| QA / Revision loop | QA Agent checks output, Revision Agent creates correction brief on failure | Quality gate before delivery | Not built |
| Delivery Manager | Final agent that writes the user-facing response after QA passes | Last step before responding to the user | Not built |
| Memory Agent | Saves memory into PostgreSQL and/or GitHub doc files automatically | Reduces manual doc updates | Not built |

### ❌ Rejected / removed
| Feature | Reasoning |
|---|---|
| LiteLLM as model gateway | Removed from the final stack — n8n and OpenHands now call OpenRouter directly, which is simpler and removes an unnecessary layer. |
| n8n Code / Function / Python / JS nodes | Decided against using custom code nodes inside n8n — logic and routing should be handled by AI Agent nodes instead, to keep the workflow auditable and consistent. |
| Separate Research Agent + Switch branch for web search | Drafted in `workflows/ai-factory-v3.json` (`01C_Intent_Router` -> `02A_SearXNG_Search` -> `02B_Research_Agent`), but replaced by attaching SearXNG directly as a Tool on `00_AI_General_Manager`. Fewer nodes, less to keep in sync, and lets the model decide when search is actually needed instead of a fixed pipeline step. |

## Full planned AI employee roster

(see `AGENTS.md` for full detail per agent)

Project Classifier → Requirement Clarifier → PM Agent → Product Analyst → Research Agent → UI/UX Designer (if needed) → Frontend Planner (if needed) → Backend Planner (if needed) → Database Planner (if needed) → Security Reviewer → Software Architect → Execution Brief Builder → OpenHands Executor → QA Agent → Revision Agent → Delivery Agent → Memory Agent.

Only employees relevant to the project's needs should run — not all of them blindly.

## How to resume work in a new chat

Tell the assistant:

```text
This is the MKDD AI Factory project. Read PROJECT_MASTER_CONTEXT.md, CURRENT_STATUS.md,
NEXT_STEPS.md, DECISIONS_LOG.md, BUGS_AND_FIXES.md, and PROJECT_SUMMARY.md,
then continue from the latest step.
```
