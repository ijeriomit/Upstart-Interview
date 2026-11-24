class AddDemoPasswordAndAccountType < ActiveRecord::Migration[8.1]
  def change
    # Keep the old digest column during the transition so a rollback can still
    # use the previous session draft. Existing users get passwords via seeds.
    add_column :users, :password, :string
    add_column :accounts, :account_type, :string
    add_check_constraint :accounts,
      "account_type IN ('checking', 'savings', 'credit')",
      name: "accounts_type_valid"
  end
end
