# Accounts Dashboard

Accounts Dashboard is an interview starter with an Ember frontend, an API-only Rails backend, Pundit, PostgreSQL, and SCSS. Alex and Jordan are seeded demo users with separate accounts.

Ember source lives in `frontend/`. Add new routes and components there since Ember CLI’s built-in generators still target `app/`.

## Run locally in VS Code

Use Ruby 3.4.13, a current Node 22 release, and a running Docker Desktop. `.nvmrc` selects the Node 22 release line. If an existing VS Code terminal still finds the system Ruby, load the Mise setup with `source ~/.zprofile`.

If you already have a local database, run `docker volume ls --filter label=com.docker.compose.volume=fieldwork_postgres` to find its volume. Set `COMPOSE_PROJECT_NAME` to the prefix of that volume name before `_fieldwork_postgres` in the terminal where you run Compose so it reuses your data.

1. Open the workspace root and run the following commands in its terminal.

   ```sh
   nvm install
   docker compose up -d --wait db
   npm ci
   ```

2. Start the Rails JSON API in another terminal. Set `DEMO_ALEX_PASSWORD` and `DEMO_JORDAN_PASSWORD` in that terminal to provision passwords for the local demo accounts.

   ```sh
   cd backend
   bundle install
   bin/rails db:prepare
   bin/rails db:seed
   bin/rails server -b localhost
   ```

3. Run `npm start -- --host 127.0.0.1` from the workspace root and open [Accounts Dashboard](http://localhost:4200). Vite forwards `/api` to Rails on port 3000. Compose publishes PostgreSQL on `http://localhost:5433` with separate development and test databases.

Run `nvm use` before npm commands in a new terminal. If `npm ci` reports `EBADENGINE`, use `nvm install` to update Node 22 and rerun `npm ci`. Older Node versions can cause npm to skip the platform-specific Rolldown binding.

Open **Sign in** and use `alex@example.test` or `jordan@example.test` with the corresponding password. A fresh development database needs the demo password variables before it can create those users. Rerun `bin/rails db:seed` to fill in missing demo credentials while preserving existing passwords, accounts, and transactions.

Use `docker compose stop db` to stop the database and keep its data.

## Walk through one transaction

1. **Ember loads the screen.** The account route receives the ID from the URL and uses an injected API service to fetch the summary. The service loads Rails JSON into Ember Data records for users, accounts, and transactions. The account screen reads its balance and history from the account record. The form action reads `FormData` as strings. Tracked fields drive its saving, success, and error messages. [Route](frontend/routes/accounts/show.js) · [API service](frontend/services/accounts-api.js) · [Form](frontend/components/transaction-form.gjs)
2. **Rails checks access.** A Pundit scope limits the SQL query to the current user’s accounts. A policy answers whether that user can perform an action on a particular record. A lookup outside the scope returns `404`, which also covers an ID that does not exist. [Account policy](backend/app/policies/account_policy.rb) · [Transaction policy](backend/app/policies/transaction_policy.rb)
3. **PostgreSQL serializes writes to the account.** `with_lock` reloads the account and holds a row lock for the database transaction. The entry and balance update commit together. If a debit would overdraw the account, the balance validation raises and both writes roll back. Other processes using the same row must wait for the lock. A Ruby `Mutex` coordinates threads sharing that mutex in one process. [Write service](backend/app/services/post_transaction.rb)
4. **Money stays exact.** PostgreSQL `decimal(19, 2)` allows 17 whole digits and two decimal places. Rails parses amount strings into `BigDecimal` and returns balances, totals, and amounts as strings. Ember adds display separators as text. After a save, the API service updates the existing account record and its transaction history from the server response. [Decimal helper](backend/app/models/usd_amount.rb) · [Summary service](backend/app/services/account_summary.rb) · [Ember display helper](frontend/helpers/usd.js)

## API examples

| Method and path                       | Response                                                           |
| ------------------------------------- | ------------------------------------------------------------------ |
| `GET /api/csrf`                       | CSRF token for the current browser session                         |
| `POST /api/session`                   | Signs in with `{ session: { email, password } }`                   |
| `DELETE /api/session`                 | Revokes the session and returns HTTP `204`                         |
| `GET /api/me`                         | Signed-in user                                                     |
| `GET /api/accounts`                   | Accounts in the current user’s scope                               |
| `GET /api/accounts/:id`               | Balance, credit/debit totals, and newest-first transaction history |
| `POST /api/accounts/:id/transactions` | Updated summary with HTTP `201`                                    |

For API writes, send the session cookie and the value from `GET /api/csrf` in `X-CSRF-Token`. Fetch a fresh token after signing in or out. To post a transaction, send `{"transaction":{"direction":"credit","amount":"12.34","description":"Practice deposit"}}` as JSON. Error responses include `error.code` and `error.message`. The API uses `400` for an invalid request shape, `401` for missing or invalid credentials, `403` for a denied action, `404` for a missing or out-of-scope record, and `422` for invalid amounts or failed validations.

Run `bundle exec rspec` from `backend/` to run the Rails request, policy, and service specs. From the workspace root, `npm test` opens Chrome and keeps the frontend results visible. Press Enter in Testem to rerun or `q` to quit. Use `npm run test:ci` for a headless run that exits when the tests finish.

The SCSS uses simple typography, grouped cards, and direct form labels inspired by Upstart’s public product pages. Tokens and layout rules live in one place. [Upstart personal loans](https://www.upstart.com/personal-loans) · [SCSS](frontend/styles/accounts-dashboard.scss)
