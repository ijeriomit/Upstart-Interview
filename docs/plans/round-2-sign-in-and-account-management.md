# Round 2 — Sign-in and account management

**Status.** Round 2 is split into five branches for individual review and implementation. The earlier Rails session draft is preserved on its feature branch. Finalizing that branch starts with a local mock credential flow.

## Feature branches

| Branch                              | Scope                                                                                                                                                              |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `feature/frontend-sign-in-form`     | Standalone Ember sign-in form and its browser validation.                                                                                                          |
| `feature/frontend-session-menu`     | Builds on the form branch. Holds the sign-in route, hamburger actions, session restoration, and store cleanup.                                                     |
| `feature/frontend-account-deletion` | Delete action, warning, and typed-name confirmation. Integrate with the closure API after its contract is ready.                                                   |
| `feature/backend-users-sessions`    | Create-user action, sessions, and demo credential setup. The branch uses plain-text mock passwords and creates typed opening accounts atomically.                |
| `feature/backend-account-closure`   | Retain closed accounts and their ledger rows, filter both Pundit scopes to open accounts, and update policy specs.                                                 |

Account creation, account types, and the overdraft limit remain in the Round 2 acceptance criteria. Their branch placement is pending.

## Acceptance criteria

- Signed-out visitors see **Sign in** and **Sign up** in the hamburger menu. Signed-in users see **Sign out**. Refresh restores the session. Signing out returns the browser to a public route and clears private account data. A protected API request without a valid session returns `401`.
- Existing users receive passwords before the switch to session-based sign-in. Their user IDs, account ownership, and transaction history are preserved.
- Registration welcomes the user and collects their details, password, and one or more opening accounts. Each account needs a name, an account type, and a nonnegative initial deposit. `0` is valid. Nonnumeric amounts, negative amounts, and amounts with more than two decimal places prevent submission. Form help and validation messages work with keyboard, touch, and screen readers. Rails validates the same rules.
- Signup saves the user, accounts, and positive opening-deposit transactions together. An invalid second account leaves no user, accounts, or transactions behind. A zero deposit leaves the account at `0.00`.
- Signed-in users can create and delete their own accounts. The list and detail views show `checking`, `savings`, or `credit`. A debit can bring any account type down to `-1000.00`. A debit below that limit leaves both the balance and transaction count intact.
- Deletion requires an exact zero balance and the typed account name. The confirmation dialog names the account, explains what will happen, and supports keyboard dismissal and focus return. Rails rechecks the name and balance. Positive and negative balances block deletion. Another user's account returns `404`.
- Closing an account retains the account and its transactions in PostgreSQL. Users can see only their own open accounts and transactions from those accounts. A direct request for a closed account returns `404`.

## Proposed API contract

Keep Rails' plain JSON envelopes and `{ error: { code, message } }` errors. IDs and money remain strings. New money fields use decimal strings such as `"25.00"`.

| Endpoint                   | Request and outcome                                                                                                                                                                                                         |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GET /api/csrf`            | Return `{ csrfToken }` for same-origin forms and refresh it after session rotation.                                                                                                                                         |
| `POST /api/session`        | Accept `{ session: { email, password } }`. Set a session cookie and return `200` with `{ user }`. Invalid credentials return `401`.                                                                                         |
| `GET /api/me`              | Return `{ user }` for the session identity or `401` when signed out. Preserve the existing ID and email checks when supplied.                                                                                               |
| `DELETE /api/session`      | Revoke the session, clear the cookie, and return `204`.                                                                                                                                                                     |
| `POST /api/users`          | Accept `{ user: { name, email, password }, accounts: [{ name, accountType, initialDeposit }] }`. Return `201` with `{ user }` and send the browser to sign-in.                                                              |
| `POST /api/accounts`       | Require a valid session and accept `{ account: { name, accountType } }`. Take ownership from the session. Return `201` with the new zero-balance `{ account }`, `401` when signed out, or `422` for invalid account fields. |
| `DELETE /api/accounts/:id` | Accept `{ account: { confirmationName } }`. Return `204` on closure, `409` for a nonzero balance, and `422` for a missing or mismatched name.                                                                               |

Account list and detail responses add `accountType` to their existing account fields. Pundit filters those responses to open accounts owned by the signed-in user and hides transactions from closed accounts. List records stay partial so refreshing the list preserves detail totals and transaction relationships in Ember. The API client handles `204` before parsing JSON.

## Proposed slices and owners

### 1. Session identity and navigation

- **Backend agent.** Use a mock credential check and preserve the session API needed by Ember. Store the demo password in the user row without bcrypt, as agreed for this interview project. Never include it in API responses or request logs.
- **Existing-user setup.** Preserve Alex and Jordan's existing records and their account history. Seeds give missing credentials a documented mock password, with local environment overrides. Verify both identities can sign in before switching protected routes to session identity.
- **Frontend agent.** Add `menu.gjs` to the application shell and a public `/sign-in` route. Restore tracked session state with `/api/me` before loading account routes. Distinguish a `401` from a network failure. On session change, clear protected route and Ember Data state and ignore late replies from the previous session before they reach the store.
- **Proof.** Rails request specs exercise login, `/api/me`, invalid credentials, CSRF, and logout with separate clients. Verify that provisioning an existing user preserves their ID and access to their existing accounts, and that seeds preserve an existing password on rerun. Ember acceptance covers menu states, refresh, and a delayed response from the previous user arriving after sign-out.

### 2. Account types and overdraft limit

- **Backend agent.** Add `account_type` with matching PostgreSQL and Rails constraints. Backfill known demo types while keeping IDs, ownership, balances, and ledger entries. Update the model and database balance bounds to accept `-1000.00` exactly. Reuse the posting service and its account row lock. Update the existing rollback spec to exceed the new limit.
- **Frontend agent.** Add `accountType` to Ember Data normalization and display. Keep exact decimal strings and show the minus sign before the currency symbol.
- **Proof.** Verify the migration against existing rows, type validation in Rails and PostgreSQL, exact boundary acceptance, rejection one cent beyond it, and protection against concurrent debits exceeding the limit.

### 3. Registration and account creation

- **Backend agent.** Add `UsersController#create` and `AccountsController#create`. Wrap signup in one database transaction and associate opening accounts with the newly created user. Reuse exact amount parsing and the existing posting path for positive opening deposits. For standalone creation, build through `current_user.accounts`, permit only the name and type, and authorize through Pundit. Validate a nonblank name and supported type. Enforce per-user name uniqueness at the database boundary.
- **Frontend agent.** Add `/sign-up`, link it from the menu, and add a short welcome and the registration form. Reuse the existing tracked form pattern for reactive validation, accessible tooltips, and submit state. Match Rails' deposit format of up to 17 whole digits and two decimal places. The account creation form sends the required name and type.
- **Proof.** Request specs cover atomic signup rollback and positive and zero deposits. For account creation, sign in as Alex and submit a valid account with Jordan's `user_id` in the payload. Assert that the saved account belongs to Alex and Jordan's account count stays the same. Verify that signed-out requests, blank names, and unsupported types create no account. Ember tests cover blank names, nonnumeric and negative deposits, zero, and successful submission.

### 4. Account closure

- **Backend agent.** Use `closed_at` as the status source. A null value means open and a timestamp means closed. Authorize closure through Pundit and set `closed_at` after rechecking the confirmation name and exact zero balance under the same account row lock used for posting. Keep the account and its transaction rows. Update `AccountPolicy::Scope` to return owned, open accounts. Update `TransactionPolicy::Scope` to preserve incoming filters and include only transactions from those accounts. Require an open account for show and transaction creation, and recheck that status after acquiring the posting lock.
- **Frontend agent.** Add a delete action on account detail and a keyboard-accessible confirmation dialog. Check the exact name and canonical `0.00` balance. Show a server conflict if the balance changes during confirmation. After success, remove the account from the active store and return to the list. Guard against an older read restoring the closed account.
- **Proof.** Request specs check zero, positive, negative, wrong-name, and foreign-account cases. Verify that closure retains account and transaction rows, removes the account from the list, and makes direct account reads and new posts return `404`. Direct specs for both Pundit scopes verify that even the owner cannot see a closed account or its transactions. A concurrent posting-versus-closure spec verifies the row-lock boundary. Ember acceptance covers typing the name, refusal, and removal after success.

## Sequence and approval

The orchestrator freezes the API contract for each approved slice before backend and frontend agents work in parallel. Registration depends on sessions and account types. Closure depends on the account contract and the existing posting lock. The review agent independently checks authorization, migration safety, data races, and acceptance coverage. Run `bundle exec rspec` from `backend/` and `npm run test:ci` from the workspace root for each integrated slice that touches both layers.

**Decisions to confirm before the relevant slice.** Backfill known demo types and approve a classification rule for remaining accounts. Treat typing the name as account deletion confirmation. Confirm whether closed account names stay reserved under the current unique constraint. Confirm a credential enrollment path if there are existing users outside the local environment.

**Migration and recovery.** Add fields, run a repeatable backfill, and verify existing records before enforcing required types. Coordinate the database and Rails overdraft change before accepting negative balances. A rollback must preserve session authorization and keep closed accounts out of active queries. After negative balances exist, returning to the old database bound would fail until those balances are addressed. Use a forward correction when rollback would expose closed accounts or reject existing balances.

The demo password column is additive and leaves the earlier digest column in place. Once users register through the new endpoint, rolling this migration back would discard their mock passwords. Preserve a database backup and use a forward correction after registration data exists.

**Pre-split verification.** Chrome passed 21 Ember examples on the original session draft. Ruby syntax checks passed. Rails runtime verification stopped at the missing bcrypt gem. Validate the frontend and backend again as their branches are finalized.
