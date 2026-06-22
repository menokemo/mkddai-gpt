# Current Status

## Working

- Docker stack is running.
- PostgreSQL is running.
- n8n is running.
- Open WebUI is running.
- OpenHands is running.
- SearXNG is running.
- Redis is running.
- `00_AI_General_Manager` is working.
- Postgres Chat Memory is working.
- OpenWebUI Pipe v1.0.3 filters internal helper prompts.
- Memory pollution from OpenWebUI title/tags/followups was diagnosed and fixed.

## Current Workflow Shape

```text
01_Client_Intake
  -> 00_AI_General_Manager
  -> 01B_Intent_Analyzer / planned
  -> 99_Client_Response
```

## Current Risk

Memory currently used a fixed session key during testing:

```text
mkddai-main-chat
```

This must be changed to use real `chat_id` from OpenWebUI.

## Latest Successful Behavior

The General Manager remembered the user name after the Pipe filtered OpenWebUI internal prompts.

## Latest Architectural Decision

Do not turn General Manager into a parser. Keep it conversational. Put classification/routing in hidden nodes after it.
