class User < ApplicationRecord
  # inverse_of links user.accounts and account.user in memory. Destroying a
  # user raises while they still own accounts.
  has_many :accounts, inverse_of: :user, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
