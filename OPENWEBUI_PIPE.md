# OpenWebUI Pipe

## Current Pipe Version

```text
1.0.3
```

## Purpose

The Pipe sends real user messages from Open WebUI to n8n.

It also filters OpenWebUI internal helper prompts:

- chat title generation
- tag generation
- follow-up question generation

These internal prompts must not reach n8n memory.

## Payload sent to n8n

```json
{
  "message": "real user message",
  "chat_title": "chat title or id",
  "chat_id": "chat/session id"
}
```

## n8n Memory

The n8n Postgres Chat Memory should eventually use:

```text
{{ $json.chat_id }}
```

as the session key, instead of the temporary:

```text
mkddai-main-chat
```
