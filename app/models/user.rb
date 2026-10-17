class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  # has_secure_password checks presence and the 72-byte bcrypt cap only;
  # the security guide leaves minimum length to us.
  validates :password, length: { minimum: 10 }, on: :create

  # The DB has a unique index but no model rule, so a duplicate (or blank)
  # email surfaced as a raw PG::UniqueViolation from bin/rails users:create
  # instead of a validation message — probed: the task died with a full
  # backtrace and `if user.save` never reached its errors branch.
  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
