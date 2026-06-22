# PostgreSQL Database Plan

## Purpose

PostgreSQL will be the real memory layer.

## Tables

### ai_projects

Stores project-level metadata.

### ai_project_memory

Stores memory and decisions.

### ai_agent_runs

Stores each agent run summary.

### ai_tasks

Stores tasks and ownership.

### ai_qa_reports

Stores QA results.

## Initial Schema

The v3 installer includes initial tables:

```text
ai_projects
ai_project_memory
ai_agent_runs
ai_tasks
ai_qa_reports
```

## Memory Strategy

Use PostgreSQL for structured memory and GitHub markdown files for human-readable memory.
