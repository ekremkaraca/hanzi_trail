class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # has_secure_password checks presence and the 72-byte bcrypt cap only;
  # the security guide leaves minimum length to us.
  validates :password, length: { minimum: 10 }, on: :create

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
