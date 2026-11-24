import { USER_FIXTURE } from './accounts-fixtures';

// Fake only the identity endpoints used by acceptance tests.
export function handleUserRequest(path, options, state) {
  switch (path) {
    case '/me':
      if (!state.currentUser) {
        throw Object.assign(new Error('Sign in required.'), { status: 401 });
      }
      return { user: state.currentUser };
    case '/session': {
      const { session } = JSON.parse(options.body);
      const existingLogin =
        session.email === USER_FIXTURE.email &&
        session.password === 'mock-password';
      const newLogin =
        session.email === state.registeredUser?.email &&
        session.password === state.registeredPassword;
      if (!existingLogin && !newLogin) {
        throw Object.assign(new Error('Invalid email or password.'), {
          status: 401,
        });
      }
      state.currentUser = newLogin ? state.registeredUser : USER_FIXTURE;
      return { user: state.currentUser };
    }
    case '/users': {
      const registration = JSON.parse(options.body);
      state.registrations.push(registration);
      if (registration.user.email === USER_FIXTURE.email) {
        throw Object.assign(new Error('Email has already been taken.'), {
          status: 422,
        });
      }
      state.registeredUser = {
        id: '3',
        name: registration.user.name,
        email: registration.user.email,
      };
      state.registeredPassword = registration.user.password;
      state.registeredAccounts = registration.accounts.map(
        (account, index) => ({
          id: String(index + 3),
          name: account.name,
          balance: Number(account.initialDeposit).toFixed(2),
        }),
      );
      return { user: state.registeredUser };
    }
    default:
      throw new Error(`Unexpected user API request: ${path}`);
  }
}
