# AI Employees

## Employee List

### 1. Project Classifier Agent

Classifies the request.

Expected output:

```text
PROJECT_TYPE:
NEEDS_UI:
NEEDS_BACKEND:
NEEDS_DATABASE:
NEEDS_MOBILE_APP:
NEEDS_AI:
COMPLEXITY:
SUMMARY:
```

### 2. Requirement Clarifier Agent

Asks focused questions when the request is incomplete.

### 3. PM Agent

Produces PRD:

- project goal
- users
- scope
- features
- user stories
- acceptance criteria
- risks
- milestones
- out of scope

### 4. Product Analyst Agent

Produces:

- personas
- journeys
- functional requirements
- edge cases
- priorities

### 5. Research Agent

Uses SearXNG later if needed.

Produces:

- market notes
- competitor patterns
- best practices
- implementation recommendations

### 6. UI/UX Designer

Runs only if UI is needed.

Produces:

- sitemap
- pages
- components
- flows
- states
- RTL
- accessibility

### 7. Frontend Planner

Runs only if frontend is needed.

Produces:

- page plan
- component plan
- state plan
- API integration points
- frontend test cases

### 8. Backend Planner

Runs only if backend is needed.

Produces:

- services
- APIs
- auth
- validation
- error handling
- backend test cases

### 9. Database Planner

Runs only if database is needed.

Produces:

- entities
- tables
- relations
- indexes
- data validation
- privacy notes

### 10. Security Reviewer

Reviews:

- auth risks
- secret handling
- data privacy
- unsafe defaults
- abuse cases

### 11. Software Architect

Produces:

- tech stack
- folder structure
- implementation phases
- files to create
- commands/tests
- constraints
- definition of done

### 12. Execution Brief Builder

Builds strict OpenHands brief.

### 13. OpenHands Executor

Executes code in the repo.

### 14. QA Agent

Outputs:

```text
QA_STATUS: pass/fail
```

And lists problems and required fixes.

### 15. Revision Agent

Creates a correction brief if QA fails.

### 16. Delivery Agent

Writes final user-facing response.

### 17. Memory Agent

Saves memory into PostgreSQL and/or GitHub files.

## Agent Rule

Agents should not all run blindly.

The workflow should route them based on project needs.
