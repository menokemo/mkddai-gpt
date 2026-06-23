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

## Decision: Web search is a Tool on the General Manager, not a separate pipeline branch

The General Manager (`00_AI_General_Manager`) has n8n's native **SearXNG** tool node attached directly to its `ai_tool` input. The model decides itself when to search and what to search for (via n8n's `$fromAI`-style tool calling), rather than routing through a fixed Intent Analyzer -> Switch -> Research Agent pipeline. This is simpler, has fewer nodes, and matches how a real agent should behave (deciding on its own when a tool is needed) instead of a rigid sequential step. The earlier draft of a separate Research Agent + Switch branch was abandoned in favor of this.

## Decision: SearXNG JSON output must be enabled at install time

The installer pre-creates `searxng/settings.yml` with `format: json` enabled before the stack starts, instead of relying on SearXNG's own defaults (which disable JSON). This was required for any tool/HTTP call expecting structured search results to work without a manual server-side edit after install.
