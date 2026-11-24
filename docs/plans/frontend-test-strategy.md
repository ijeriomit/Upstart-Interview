# Frontend Test Refactor Plan (Accounts Dashboard)

## Goal
Simplify overgrown acceptance coverage for the accounts dashboard while improving confidence through a clearer split between acceptance, integration, and unit tests.

## Scope
- Frontend test suite only.
- No product behavior changes.
- No backend/Rails test changes in this plan.

## Acceptance Criteria
- Acceptance tests read as short end-user journeys instead of transport/store implementation details.
- Shared setup and fixture logic is extracted into reusable helpers.
- Integration tests cover `accounts-api` service behavior and frontend/backend interaction boundaries.
- Unit tests cover serializer normalization contracts.
- Existing retry/staleness behavior remains covered and understandable.

## Test Layer Responsibilities

### Acceptance Tests
- Verify user-visible workflows and route transitions.
- Verify visible success/error UI states.
- Avoid deep assertions about transport internals when those are covered by integration tests.

### Integration Tests (Service)
- Verify service request paths/methods/headers/body contracts.
- Verify stale-read retry behavior and bounded attempts.
- Verify store interaction boundaries (`store.push` payload use).
- Verify API error mapping behavior.

### Unit Tests (Serializer)
- Verify pure normalization output shape.
- Verify account list stays partial.
- Verify IDs and money values remain string-preserving.
- Verify account summary relationships/included transactions structure.

## Planned Phases

### Phase A — Acceptance Helper Extraction (current)
- Add reusable acceptance fixtures and API stub helpers.
- Refactor acceptance tests to use helpers without changing behavior.

### Phase B — Service Integration Tests
- Add `tests/integration/services/accounts-api-test.js`.
- Move transport and retry invariants from acceptance focus into integration coverage.

### Phase C — Serializer Unit Tests
- Add `tests/unit/serializers/accounts-api-test.js`.
- Cover normalization contracts independently from route/UI behavior.

### Phase D — Acceptance Simplification
- Keep a lean set of high-value journeys.
- Remove deep assertions that are better owned by integration/unit layers.

### Phase E — Validation and Cleanup
- Run `npm run test:ci`.
- Resolve regressions introduced by the refactor only.

## Risks and Mitigations
- **Risk:** Losing confidence while moving assertions across layers.
  - **Mitigation:** Migrate assertions incrementally, preserving coverage intent per phase.
- **Risk:** Helpers become too specific to one page.
  - **Mitigation:** Keep helpers data-first and selector-light where possible.

## Approval Gates
- Approve each phase before moving to the next.
- Significant test architecture changes should be reviewed with rationale and diff summary.
