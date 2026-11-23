class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.string :direction, null: false
      t.decimal :amount, precision: 19, scale: 2, null: false
      t.string :description, limit: 120
      t.timestamps
    end

    # Match the account filter and newest-first history query with one index.
    add_index :transactions, [:account_id, :created_at, :id], order: { created_at: :desc, id: :desc }
    add_check_constraint :transactions, "direction IN ('credit', 'debit')", name: "transactions_direction_valid"
    add_check_constraint :transactions, "amount > 0 AND amount <= 99999999999999999.99", name: "transactions_amount_in_range"
  end
end
