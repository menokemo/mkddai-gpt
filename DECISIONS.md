# Decisions

## 1. LiteLLM removed from v3

Decision: Remove LiteLLM from the final v3 script.

Reason:

- n8n already has OpenRouter Chat Model support.
- OpenHands works better with OpenRouter direct.
- LiteLLM added complexity and debugging overhead.
- The no-code workflow goal is better served by n8n Chat Model nodes.

## 2. PostgreSQL remains and expands

Decision: PostgreSQL stays in the stack and becomes the future system memory database.

Reason:

- n8n needs a database.
- The AI Factory needs durable project memory.
- PostgreSQL is better than files alone for structured status, logs, and tasks.

## 3. n8n AI Agent nodes are the employee layer

Decision: Employees should be n8n AI Agent nodes.

Reason:

- Prompts are editable as normal text.
- Models are selected through Chat Model nodes.
- This avoids raw JSON employee nodes.
- It matches the no-code requirement.

## 4. OpenRouter is the direct model provider

Decision: n8n AI Agents use OpenRouter Chat Model directly.

OpenHands also uses OpenRouter directly from its own UI settings.

## 5. OpenHands is executor only

Decision: OpenHands should not be the PM, architect, or product owner.

OpenHands receives a strict implementation brief from n8n.

## 6. GitHub is required

Decision: GitHub is required as the project source of truth.

It stores:

- system documentation
- project code
- decisions
- memory markdown
- tasks
- delivery history

## 7. Workflow should be smart, not short

Decision: More nodes are acceptable.

The workflow should use IF/Switch/Merge logic so employees do not behave like a dumb linear chain.

## 8. No code nodes in n8n

Decision: No JavaScript, Python, Function, or Code nodes inside n8n.

Allowed nodes:

- AI Agent
- OpenRouter Chat Model
- IF
- Switch
- Merge
- Edit Fields
- PostgreSQL
- GitHub
- HTTP Request for OpenHands only
- Respond to Webhook
