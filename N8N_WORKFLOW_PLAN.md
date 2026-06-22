# n8n Workflow Plan v3

## Working Base

The following chain was tested successfully:

```text
Webhook /webhook/ai-factory-v3
  -> AI Agent
  -> OpenRouter Chat Model
  -> Respond to Webhook
```

The AI Agent successfully read:

```text
body.message
```

and classified:

```text
اعمل منصة SaaS لإدارة العيادات
```

## Build Method

Build manually inside n8n.

Do not import large generated JSON workflows for the main system.

## Stage 1: Classifier

```text
Webhook
  -> Project Classifier Agent
  -> Respond
```

Status: working.

## Stage 2: PM Agent

```text
Webhook
  -> Project Classifier
  -> PM Agent
  -> Respond
```

## Stage 3: Product Agent

```text
Classifier
  -> PM
  -> Product Analyst
```

## Stage 4: Routing

Add IF nodes:

```text
IF NEEDS_UI
IF NEEDS_BACKEND
IF NEEDS_DATABASE
IF NEEDS_AI
```

## Stage 5: Specialized Agents

Add:

```text
UI/UX Agent
Frontend Planner
Backend Planner
Database Planner
Security Reviewer
Software Architect
```

## Stage 6: GitHub

Add GitHub repo resolver:

```text
IF repo_url exists
  -> Use existing repo
else
  -> Create repo
```

## Stage 7: OpenHands

Add OpenHands execution through HTTP Request.

This is allowed because OpenHands is a service integration, not an employee.

## Stage 8: QA and Delivery

```text
OpenHands
  -> QA Agent
  -> IF QA_STATUS pass
      -> Delivery
      -> Revision Agent -> OpenHands retry once
```

## Stage 9: Memory

Use PostgreSQL nodes to save:

- project
- memory
- tasks
- QA report
- delivery summary
