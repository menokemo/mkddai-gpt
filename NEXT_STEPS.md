# Next Steps

## Step 1: Fix Session Key

In `Postgres Chat Memory` connected to `00_AI_General_Manager`, change Session Key from:

```text
mkddai-main-chat
```

to:

```text
{{ $json.chat_id }}
```

Make sure OpenWebUI Pipe sends `chat_id`.

## Step 2: Build Intent Analyzer

Add an AI Agent named:

```text
02_Intent_Analyzer
```

It should be hidden/internal and return one short label only.

Initial labels:

```text
CHAT
PROJECT
RESEARCH
TECH_SUPPORT
BUSINESS
CONTINUE_PROJECT
```

## Step 3: Add Switch Router

Route based on `02_Intent_Analyzer` output.

## Step 4: Research Path

If `RESEARCH`:

```text
Research Agent -> General Manager Response -> Client Response
```

Use SearXNG later.

## Step 5: Project Path

If `PROJECT`:

```text
Save Project -> PM Agent -> Product Analyst -> Architect
```

## Step 6: Execution Path

Later:

```text
GitHub Manager -> OpenHands Executor -> QA -> Delivery
```

## Step 7: Keep Docs Updated

Run:

```bash
./sync_docs.sh
```

after replacing or editing project documentation locally.
