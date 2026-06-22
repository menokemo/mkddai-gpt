# OpenWebUI Pipe

## Version

```text
1.0.3
```

## Purpose

Send only real user messages to n8n.

Filter OpenWebUI internal helper prompts.

## Required Payload

```json
{
  "message": "real user message",
  "chat_title": "chat title or id",
  "chat_id": "chat/session id"
}
```

## Important

n8n Memory should use `chat_id` as session key, not a fixed value.
