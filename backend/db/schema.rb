# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_24_000200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.decimal "balance", precision: 19, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "account_type"
    t.index ["user_id", "name"], name: "index_accounts_on_user_id_and_name", unique: true
    t.check_constraint "account_type::text = ANY (ARRAY['checking'::character varying, 'savings'::character varying, 'credit'::character varying]::text[])", name: "accounts_type_valid"
    t.check_constraint "balance >= 0::numeric AND balance <= 99999999999999999.99", name: "accounts_balance_in_range"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "direction", null: false
    t.decimal "amount", precision: 19, scale: 2, null: false
    t.string "description", limit: 120
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at", "id"], name: "index_transactions_on_account_id_and_created_at_and_id", order: { created_at: :desc, id: :desc }
    t.check_constraint "amount > 0::numeric AND amount <= 99999999999999999.99", name: "transactions_amount_in_range"
    t.check_constraint "direction::text = ANY (ARRAY['credit'::character varying::text, 'debit'::character varying::text])", name: "transactions_direction_valid"
  end

  create_table "user_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "password"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "transactions", "accounts"
  add_foreign_key "user_sessions", "users"
end
