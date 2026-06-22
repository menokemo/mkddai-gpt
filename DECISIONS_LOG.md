# Decisions Log

## Decision: Remove LiteLLM

LiteLLM is removed from the final stack. n8n and OpenHands use OpenRouter directly.

## Decision: PostgreSQL is mandatory

The installer must create all AI Factory database tables automatically.

## Decision: General Manager is the user-facing layer

The user talks to `00_AI_General_Manager`, not directly to PM, Architect, or OpenHands.

## Decision: Intent Analyzer is hidden

Routing/classification should be done by a hidden node after the General Manager.

## Decision: No n8n code nodes

Avoid Code, Function, JavaScript, and Python nodes inside n8n.

## Decision: OpenWebUI internal prompts must be filtered

OpenWebUI sends internal prompts for titles, tags, and followups. The Pipe must filter them.

## Decision: GitHub is the source of truth

Docs, scripts, decisions, current state, and next steps should be kept in GitHub.
