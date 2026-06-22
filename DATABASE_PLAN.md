# PostgreSQL Database Plan

PostgreSQL is required and must be created automatically by the installer.

## Tables

### ai_projects

Stores real project records.

### ai_conversations

Stores conversation/session records.

### ai_messages

Stores clean user/assistant messages for long-term conversation memory.

### ai_project_memory

Stores project decisions, summaries, next actions, and risks.

### ai_agent_runs

Stores each employee/agent run.

### ai_tasks

Stores generated tasks.

### ai_qa_reports

Stores QA results and revision state.

### ai_research_reports

Stores internet/search research output.

### ai_builder_temporary_workflow

Temporary builder/debug workflow storage.

### n8n_chat_histories

Used by n8n Postgres Chat Memory.

## Key Rule

Do not manually create these tables on a fresh VM. The installer must create them.
