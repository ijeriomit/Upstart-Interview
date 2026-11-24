# Frontend demo access

The `/sign-in` and `/sign-up` screens currently provide a local preview for the
interview exercise. They do not call the Rails API. `DemoAccessService` holds the
preview in memory, so refreshing the page clears it. The sign-up password is
read from the form but is not saved in the preview.

## Sign-up form

`SignUpForm` owns the opening account rows. Each row has a stable ID so deleting
one row does not mix up the other rows' inputs. The form reads repeated account
fields with `FormData.getAll()`, which returns them in the same order as the
visible rows. It passes a user object and account list to `SignUpController`.
The controller stores the preview and opens `/demo-accounts`.

The browser's required and email checks prevent submission of missing fields or
an invalid email. The deposit pattern permits nonnegative decimal strings with
at most two fractional digits; `0` is valid. A tracked flag displays a deposit
error while the user types. The submit handler also trims names and rejects
names made only of spaces. These are frontend checks for the preview; the Rails
create user endpoint will need its own validation when it is connected.
Each field also has short visible help linked with `aria-describedby` and a
native hover tooltip.

## Tests

The sign-up component integration tests check validation, the callback payload,
and add/remove row behavior. The demo access acceptance tests check route
navigation, rejected sign-ups, and the accounts shown in the preview.
