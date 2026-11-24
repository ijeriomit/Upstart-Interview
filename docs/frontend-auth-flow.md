# Frontend account access

The `/sign-in` and `/sign-up` screens use `UserApiService`.
Registration sends the user and opening account rows to
`POST /api/users`, then opens sign-in. Sign-in sends credentials to
`POST /api/session`. Rails stores the account data, while the browser saves the
mock email and password in this tab's `sessionStorage`. On refresh, the frontend
sends them to `GET /api/me` to restore the identity.
The hamburger menu offers sign-in and sign-up while signed out, and sign-out
while signed in.

Protected requests send HTTP Basic credentials. Rails validates the password on
each request and Pundit scopes the resulting user's accounts. Sign-out removes
the browser credential and private Ember Data records. `identityVersion`
changes at sign-in and sign-out, so a late response from the previous user is
rejected. `AccountsApiService` handles account reads and retries a read that
started before a transaction write. `TransactionsApiService` posts transactions
and stores the returned account summary.
HTTP Basic formatting is not encryption; this credential flow is only for the
local interview project.

## Sign-up form

`SignUpForm` owns the opening account rows. Each row has a stable ID so deleting
one row does not mix up the other rows' inputs. The form reads repeated account
fields with `FormData.getAll()`, which returns them in the same order as the
visible rows. It passes a user object and account list to `SignUpController`.
The controller posts those rows through the user service and opens sign-in after
Rails accepts the registration.

The browser's required and email checks prevent submission of missing fields or
an invalid email. The deposit pattern permits nonnegative decimal strings with
at most two fractional digits; `0` is valid. A tracked flag displays a deposit
error while the user types. The submit handler also trims names and rejects
names made only of spaces. Rails validates the same account and deposit rules
before it commits the registration.
Each field also has short visible help linked with `aria-describedby` and a
native hover tooltip.

## Tests

The sign-up component integration tests check validation, the callback payload,
and add/remove row behavior. Acceptance tests check registration, sign-in,
refresh restoration, and sign-out. Rails controller request specs check actual
database writes, authorization, and atomic rollback.
