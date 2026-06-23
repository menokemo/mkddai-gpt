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

## Decision: Design mockups must be real code, not generated images, and the client chooses before execution

Two related decisions made together:

1. **Real HTML/Tailwind, not AI-generated images.** Early discussion considered using an image-generation tool (e.g. DALL-E) so the UI/UX Designer Agent could produce visual mockups. Rejected: an image is pixels, not structure — OpenHands would have to *guess* the implementation from a picture (Vision-based reconstruction), landing around 50-60% accuracy. Real HTML + Tailwind CSS gives OpenHands the actual code as a starting point instead of a guess, targeting ~90%+ implementation accuracy, at no extra image-generation API cost.

2. **Client picks between real options before any execution spend.** For any project needing UI, the system generates **2 Design Variants** per platform (e.g. web/app), each with the 3-4 most representative pages (derived from the PRD/functional requirements, not invented), as a real clickable HTML prototype. The client previews all variants on one branded Presentation Page and picks one with a single click before Architect/Security Review/Execution ever run. This avoids spending OpenHands tokens on a direction the client doesn't want, and presents the system professionally (a real interactive preview, not a description or static image).

Cost-control measures applied to this step specifically (so the added quality doesn't blow up token spend):
- A cheaper coding-focused model (e.g. DeepSeek/Qwen Coder via OpenRouter) is used for HTML/CSS generation, not GPT-4o.
- One design system (colors/fonts/spacing) is generated once per variant and reused across that variant's pages, instead of being redefined per page.
- Tailwind utility classes are used instead of verbose custom CSS.
- No separate Vision/QA agent reviews the generated mockups — the human client is the judge.
- Only the 3-4 most representative pages get a custom mockup; routine pages are left to Frontend Planner to build later using the same design system.
