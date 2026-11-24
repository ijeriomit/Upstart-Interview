seed_demo_user = ->(email, name, password_env) do
  user = User.find_or_initialize_by(email: email)
  if Rails.env.development? && user.password_digest.blank? && (password = ENV[password_env]).present?
    user.name ||= name
    user.update!(password: password)
  end
  user if user.persisted?
end

ActiveRecord::Base.transaction do
  alex = seed_demo_user.call("alex@example.test", "Alex Morgan", "DEMO_ALEX_PASSWORD")
  jordan = seed_demo_user.call("jordan@example.test", "Jordan Lee", "DEMO_JORDAN_PASSWORD")

  jordan&.accounts&.find_or_create_by!(name: "Personal checking")
  next unless alex

  alex.accounts.find_or_create_by!(name: "Rainy day savings")
  checking = alex.accounts.find_or_create_by!(name: "Everyday checking")

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
