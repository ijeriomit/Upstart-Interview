import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

export const DEMO_EMAIL = 'alex@example.test';
export const DEMO_PASSWORD = 'mock-password';

// Temporary interview preview only. No user or password is stored by this
// service, and a full page reload clears the account preview.
export default class DemoAccessService extends Service {
  @tracked preview = null;

  signIn({ email, password }) {
    if (email.toLowerCase() !== DEMO_EMAIL || password !== DEMO_PASSWORD) {
      throw new Error('Enter the demo email and password shown above.');
    }

    this.register({
      name: 'Alex Morgan',
      accounts: [
        {
          name: 'Everyday checking',
          accountType: 'checking',
          initialDeposit: '100.00',
        },
        {
          name: 'Rainy day savings',
          accountType: 'savings',
          initialDeposit: '0.00',
        },
      ],
    });
  }

  register({ name, accounts }) {
    this.preview = {
      name,
      accounts: accounts.map(({ name, accountType, initialDeposit }) => {
        // Keep balances as decimal strings: binary floating point can change
        // currency values, and the display helper expects two decimal places.
        const [whole, cents = ''] = initialDeposit.split('.');
        const balance =
          whole.replace(/^0+(?=\d)/, '') + '.' + cents.padEnd(2, '0');
        return { name, accountType, balance };
      }),
    };
  }
}
