ActiveRecord::Base.transaction do
  alex = User.find_or_create_by!(email: "alex@example.test") { |user| user.name = "Alex Morgan" }
  jordan = User.find_or_create_by!(email: "jordan@example.test") { |user| user.name = "Jordan Lee" }

  alex.accounts.find_or_create_by!(name: "Rainy day savings")
  jordan.accounts.find_or_create_by!(name: "Personal checking")
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
