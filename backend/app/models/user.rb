class User < ApplicationRecord
  has_many :accounts, inverse_of: :user, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
