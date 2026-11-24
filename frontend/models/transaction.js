import Model, { attr, belongsTo } from '@warp-drive/legacy/model';

export default class TransactionModel extends Model {
  @attr direction;
  @attr amount;
  @attr description;
  @attr createdAt;

  @belongsTo('account', { async: false, inverse: 'transactions' }) account;
}
