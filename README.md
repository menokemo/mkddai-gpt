# MKDD AI Factory v3

A self-hosted AI software-company system. The user talks to an intelligent technical General Manager through Open WebUI, who discusses ideas, researches when needed, and launches specialized AI employees to plan, build, review, and deliver software projects.

## Final Stack

```text
Open WebUI
  -> n8n Webhook
  -> 00_AI_General_Manager (Chat Model + Memory + SearXNG search Tool)
  -> 01B_Intent_Analyzer
  -> Specialized AI Employees (in progress)
  -> PostgreSQL Memory
  -> GitHub
  -> OpenHands
  -> QA / Delivery
```

No LiteLLM. No Code/Function/Python/JS nodes in n8n — drag-and-drop nodes only, for maintainability.

## Where to look for what

| File | What it's for |
|---|---|
| `CURRENT_STATUS.md` | What's actually working right now, confirmed live |
| `NEXT_STEPS.md` | The full ordered build plan for the rest of the workflow |
| `TODO.md` | Same plan as a flat checklist |
| `BUGS_AND_FIXES.md` | Every bug found, its root cause, the fix, and whether it's confirmed live |
| `CHANGELOG.md` | Dated log of every change made |
| `DECISIONS_LOG.md` | Why things were built the way they were (and what was rejected) |
| `PROJECT_SUMMARY.md` | Every feature/idea discussed — done, planned, rejected, or deferred — and why |
| `AGENTS.md` | Every AI employee's role and expected output |
| `SECURITY.md` | Secret-handling rules |
| `SERVICES.md` | Ports, folder layout, useful docker commands |
| `OPENHANDS_SETUP.md` | How OpenHands' own LLM is configured |
| `install_ai_factory_v3.sh` | The installer — source of truth for the database schema and the full Docker stack |
| `workflows/ai-factory-v3.json` | The actual exported n8n workflow, kept in sync with the live instance |

## How to resume work in a new chat

Tell the assistant:

```text
This is the MKDD AI Factory project. Read CURRENT_STATUS.md, NEXT_STEPS.md, TODO.md,
BUGS_AND_FIXES.md, DECISIONS_LOG.md, PROJECT_SUMMARY.md, and AGENTS.md, then continue
from the latest step.
```

## Installer

```bash
sudo bash install_ai_factory_v3.sh
```

Installs Docker, PostgreSQL, Redis, SearXNG (with JSON search format enabled), n8n, Open WebUI, and OpenHands, and creates all required PostgreSQL tables automatically.

To re-apply the database schema safely later:

```bash
cd /opt/ai-factory
sudo bash scripts/apply_schema.sh
```
