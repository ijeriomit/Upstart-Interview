import Model, { attr, hasMany } from '@warp-drive/legacy/model';

export default class AccountModel extends Model {
  @attr name;
  @attr balance;
  @attr totalCredits;
  @attr totalDebits;

  @hasMany('transaction', { async: false, inverse: 'account' }) transactions;
}
