class AddPasswordDigestAndUserSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :password_digest, :string

    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
