class CreateUsersAndAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :accounts do |t|
      # The compound index below also serves lookups by user_id alone.
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.decimal :balance, precision: 19, scale: 2, default: 0, null: false
      t.timestamps
    end
    add_index :accounts, [:user_id, :name], unique: true
    # The upper bound also rejects PostgreSQL's special numeric NaN value.
    add_check_constraint :accounts, "balance BETWEEN 0 AND 99999999999999999.99", name: "accounts_balance_in_range"
  end
end
