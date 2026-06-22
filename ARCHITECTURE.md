# Architecture

## v3 Architecture

```text
User
  |
  v
Open WebUI
  |
  v
Open WebUI Pipe / Function
  |
  v
n8n Webhook /webhook/ai-factory-v3
  |
  v
Project Classifier Agent
  |
  v
IF / Switch Routing
  |
  v
Specialized AI Agents
  |
  v
PostgreSQL Memory + GitHub
  |
  v
OpenHands Executor
  |
  v
QA / Revision / Delivery
  |
  v
Open WebUI Response
```

## Service Responsibilities

### Open WebUI

User interface only.

It sends the user request to n8n using a Pipe/Function.

### n8n

Main orchestration engine.

n8n controls:

- employees
- routing
- clarification
- project type
- GitHub flow
- OpenHands execution
- QA
- memory
- final response

### OpenRouter

Primary model provider for:

- n8n AI Agent Chat Models
- OpenHands direct LLM configuration

### OpenHands

Coding executor only.

OpenHands receives strict execution briefs from n8n.

### PostgreSQL

Persistent database for:

- projects
- memory
- tasks
- agent logs
- QA reports
- execution status

### GitHub

Source of truth for:

- project code
- documentation
- decisions
- delivery artifacts
- human-readable memory files

### SearXNG

Optional search source for Research Agent.

### Redis

Support/cache service.

## Core Data Flow

```text
Webhook
  -> Project Classifier
  -> IF clarification needed
  -> Switch project type
  -> PM Agent
  -> Product Analyst
  -> IF needs UI
  -> UI/UX Agent
  -> IF needs backend
  -> Backend Planner
  -> IF needs database
  -> Database Planner
  -> Security Reviewer
  -> Software Architect
  -> Execution Brief Builder
  -> GitHub repo resolver
  -> OpenHands Executor
  -> QA Agent
  -> IF QA pass
  -> Delivery Agent
  -> Memory Agent
  -> Respond to Open WebUI
```
