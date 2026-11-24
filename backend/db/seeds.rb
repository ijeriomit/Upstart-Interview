seed_demo_user = ->(email, name, password_env) do
  user = User.find_or_initialize_by(email: email)
  # Local demo users share a documented fallback password unless a developer
  # supplies a different one. Never replace a password on later seed runs.
  if Rails.env.development? && user.password.blank?
    password = ENV[password_env].presence || "mock-password"
    user.name ||= name
    user.update!(password: password)
  end
  user if user.persisted?
end

ActiveRecord::Base.transaction do
  alex = seed_demo_user.call("alex@example.test", "Alex Morgan", "DEMO_ALEX_PASSWORD")
  jordan = seed_demo_user.call("jordan@example.test", "Jordan Lee", "DEMO_JORDAN_PASSWORD")

  jordan&.accounts&.find_or_create_by!(name: "Personal checking") { |account| account.account_type = "checking" }
  next unless alex

  alex.accounts.find_or_create_by!(name: "Rainy day savings") { |account| account.account_type = "savings" }
  checking = alex.accounts.find_or_create_by!(name: "Everyday checking") { |account| account.account_type = "checking" }

  # Seed through the same operation as POST. The outer lock serializes seed
  # runs and the empty check preserves activity from any earlier run.
  checking.with_lock do
    if checking.transactions.empty?
      PostTransaction.call(checking, {
        direction: "credit", amount: "1250.00", description: "Opening deposit"
      })
      PostTransaction.call(checking, {
        direction: "debit", amount: "49.95", description: "Internet service"
      })
    end
  end
end
