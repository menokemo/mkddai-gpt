# OpenHands Setup

## Role

OpenHands is the code executor.

## LLM Configuration

Configure inside OpenHands UI:

```text
Base URL: https://openrouter.ai/api/v1
API Key: OpenRouter API key
Model: openrouter/qwen/qwen3-coder-plus
```

## Execution Rules

OpenHands receives strict briefs from n8n only.

Brief must include:

- repo URL
- branch
- scope
- architecture
- tasks
- tests
- constraints

## Do Not

Do not let OpenHands receive vague raw user requests.

Do not let OpenHands decide product scope.
