# Decisions

## LiteLLM removed

LiteLLM is removed from the final bootstrap script.

## PostgreSQL is mandatory

The installer must create all AI Factory tables automatically.

## OpenWebUI internal prompts must be filtered

OpenWebUI sends internal prompts for title/tags/follow-ups. The Pipe must filter these so memory remains clean.

## General Manager remains conversational

`00_AI_General_Manager` should behave like an expert technical general manager, not a parser.

## Workflow routing is handled separately

Intent analysis and routing should be handled by hidden nodes after the General Manager.
