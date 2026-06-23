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

## Decision: Every agent gets real timestamp context on every turn

Models have no internal clock and tend to hallucinate elapsed time from conversational patterns (e.g. claiming "last week" when the previous message was minutes ago). Fix: a `created_at` column was added to `n8n_chat_histories`, and a node (`01A_Time_Context`) fetches the real timestamp of the user's previous message on **every** incoming message — not only at the start of a session, since the hallucination happens turn-to-turn too. Every agent's system message gets both the current real time and that last-message time, and decides for itself what counts as a meaningful gap (no hardcoded threshold). This is a global rule applied to all agents, not just the General Manager — see `AGENTS.md`.

Two related decisions made together:

1. **Real HTML/Tailwind, not AI-generated images.** Early discussion considered using an image-generation tool (e.g. DALL-E) so the UI/UX Designer Agent could produce visual mockups. Rejected: an image is pixels, not structure — OpenHands would have to *guess* the implementation from a picture (Vision-based reconstruction), landing around 50-60% accuracy. Real HTML + Tailwind CSS gives OpenHands the actual code as a starting point instead of a guess, targeting ~90%+ implementation accuracy, at no extra image-generation API cost.

2. **Client picks between real options before any execution spend.** For any project needing UI, the system generates **2 Design Variants** per platform (e.g. web/app), each with the 3-4 most representative pages (derived from the PRD/functional requirements, not invented), as a real clickable HTML prototype. The client previews all variants on one branded Presentation Page and picks one with a single click before Architect/Security Review/Execution ever run. This avoids spending OpenHands tokens on a direction the client doesn't want, and presents the system professionally (a real interactive preview, not a description or static image).

Cost-control measures applied to this step specifically (so the added quality doesn't blow up token spend):
- A cheaper coding-focused model (e.g. DeepSeek/Qwen Coder via OpenRouter) is used for HTML/CSS generation, not GPT-4o.
- One design system (colors/fonts/spacing) is generated once per variant and reused across that variant's pages, instead of being redefined per page.
- Tailwind utility classes are used instead of verbose custom CSS.
- No separate Vision/QA agent reviews the generated mockups — the human client is the judge.
- Only the 3-4 most representative pages get a custom mockup; routine pages are left to Frontend Planner to build later using the same design system.

## Decision: Permanent Retention Rule for ai_projects

A project's `ai_projects` row — specifically `id`, `project_slug`, and `repo_url` — is **never deleted**, under any circumstance, even after a project is fully delivered and its working data is cleaned up to save VM disk space. Only `status` changes (e.g. to `delivered_archived`). This guarantees the project can always be found and its GitHub repo reopened later, no matter how much time has passed, even though heavier data (design variants, tasks, QA reports, memory) gets archived into the repo itself and then deleted from Postgres. Post-delivery cleanup itself only ever runs after an explicit manual confirmation — never automatically — since it's irreversible.

## Decision: One GitHub repo per project, created only after approval

Each project gets its own dedicated GitHub repo — projects are never bundled into one shared repo. The repo is created only once the client has approved the project's direction (right before Execution starts, after the Design Variants Gate / Confirmation Gate), not at the start of every conversation and not while an idea is still just being discussed.

## Decision: Webhook security uses n8n's native Header Auth, not a custom IF node

Originally planned as a custom IF node comparing a header against `$env.AI_FACTORY_WEBHOOK_SECRET`. Hit two problems: (1) recent n8n versions block `$env` access in node expressions by default for security, and n8n's own docs recommend using credentials instead of unblocking it for sensitive values; (2) it was unnecessary complexity anyway — the Webhook trigger node has a built-in `Authentication` setting (`Header Auth`) that does exactly this natively, rejecting non-matching requests with a 401 before the workflow even runs. Switched to that: zero extra nodes, no env-access workaround needed, and the secret lives in an n8n credential instead of being readable from an exported workflow JSON.
