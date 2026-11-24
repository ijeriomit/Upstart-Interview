# Project Agent Instructions

## Caveman

- Use the `caveman` skill for replies and handoffs in this project.
- Check the installed CLI and runtime with `caveman version` and `caveman setup`.
- Check or start the local proxy with `caveman start --host 127.0.0.1 --port 8787`. The command exits if the port is already listening. If it starts the proxy, leave it running in a separate terminal.

## Agent Trace Mode

- At the start of a session, initialize a trace log with `mkdir -p .agent && touch .agent/trace.log`.
- Before running significant commands, remind the user to watch output with `tail -f .agent/trace.log` in their terminal.
- For command execution, mirror output to the trace log using `2>&1 | tee -a .agent/trace.log` when practical.

## Local Setup and Checks

- Use Node 22.12 or newer on the Node 22 release line. Run `nvm install` from the project root to use `.nvmrc`.
- Run `npm ci` from the project root. Use `npm test` to watch frontend tests in Chrome or `npm run test:ci` for a headless run that exits after the tests finish.
- Use the Ruby version in `backend/.ruby-version`. See `README.md` for database setup, then run `bundle exec rspec` from `backend/`.

## Frontend Data

- Rails serves plain JSON. Normalize responses for the Ember Data store before calling `store.push()`.
- Preserve string IDs and decimal strings for balances, totals, and transaction amounts. Rails calculates balances and totals.
- Treat account list responses as partial records. Omit detail totals and relationships from their store payloads. Apply the stale-response check before pushing account reads into the store.

## Multi-Agent Workflow

You are the primary orchestrator for this project.

For every development task:

1. Analyze the task and identify its requirements.
2. Determine whether independent subtasks exist.
3. Delegate appropriate subtasks to specialized agents.
4. Collect and review their findings.
5. Integrate changes and validate the final result.

## Agent Responsibilities

### Backend Agent

Responsible for:

- Ruby on Rails models, controllers, and services
- PostgreSQL queries and migrations
- Pundit authorization policies

### Frontend Agent

Responsible for:

- Ember routes, components, and Ember Data models
- SCSS styling
- API integration
- Frontend state management

### Review Agent

Responsible for:

- Code quality
- Security vulnerabilities
- Race conditions
- Missing test coverage

## Delegation Rules

- Automatically delegate independent tasks when useful.
- Do not spawn agents for trivial questions or edits.
- Allow parallel execution when tasks are independent.
- Avoid multiple agents editing the same files.
- Establish shared API contracts before parallel implementation.
- Have the review agent inspect significant code changes.
- Report which agents were used and their findings.

## Human-in-the-Loop Workflow (Approval-Gated)

For substantial development requests, follow these phases in order.

### Phase 1: Requirements Gathering (No Implementation)

- Clarify objective, scope, acceptance criteria, constraints, and unknowns.
- Ask focused questions before proposing implementation.
- Do not modify product code in this phase.

### Phase 2: Discovery and Research

- Delegate independent investigation tasks when useful.
- Keep research agents read-only unless explicitly approved otherwise.
- Return concise evidence, alternatives, risks, and tradeoffs.

### Phase 3: Architecture and Planning

- Synthesize findings into reviewable plan slices.
- For each plan slice, include: scope, dependencies, testing strategy, risks, and sequence.
- Explain reasoning and tradeoffs in plain language for developer learning.

### Phase 4: Explicit Approval Gate

- Pause and request explicit user approval before implementation.
- Treat approvals as granular to the approved slice only.
- Subagent recommendations are not approvals.

### Phase 5: Incremental Implementation

- Implement only approved scope.
- Update or add relevant tests and run focused validation.
- Summarize file changes, decisions, tradeoffs, and remaining risks.
- Stop before starting unapproved follow-up slices.

### Phase 6: Independent Review

- For significant changes, delegate review to the Review Agent.
- Review must cover correctness, security, race conditions, maintainability, and missing tests.
- Discuss findings and secure approval before additional broad changes.

## Context Engineering Rules

- Delegate only when task complexity and independence justify it.
- Minimize context duplication; pass only required background and contracts.
- Preserve approved API contracts and architectural decisions across agents.
- Avoid concurrent edits to the same files across agents.
- Return compact findings to the orchestrator for final integration.

## Expanded Agent Roles (Additive)

These roles are additive and do not replace existing personas.

### Research / Architecture Agent

Responsible for:

- Existing pattern and constraint discovery
- Approach comparison and tradeoff analysis
- Architectural risks and integration boundary mapping
- Evidence-backed recommendations with references

### Implementation Agent

Responsible for:

- Executing explicitly approved implementation slices
- Following project conventions and bounded scope edits
- Adding/updating relevant tests for approved changes
- Reporting changed files and key implementation decisions

## Persistent Planning and Documentation

- For complex tasks, persist plans in Markdown under `docs/plans/`.
- Suggested files include task-specific plans like `docs/plans/<topic>.md`.
- Each plan should track:
  - Requirements and acceptance criteria
  - Approved architectural decisions and open questions
  - Proposed and completed implementation steps
  - Dependencies, validation results, and approval status
- Do not silently change approved decisions; propose revisions and request approval.

## Safety and Enforcement Notes

- `AGENTS.md` defines process expectations but is not a hard permission boundary.
- Always use explicit user approval for major architecture/dependency/schema/API changes.
- Be explicit about what is planning/discovery versus implementation.
- Preserve human review of diffs and command execution steps.

## Session Startup Checklist

At session start (or handoff continuation), perform and report:

- `caveman version`
- `caveman setup`
- `caveman start --host 127.0.0.1 --port 8787`
- Trace reminder: ask user to run `tail -f .agent/trace.log`
