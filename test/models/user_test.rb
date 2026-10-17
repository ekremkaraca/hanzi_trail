require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  # Regression: without these rules a duplicate email raised a raw
  # PG::UniqueViolation (users:create died mid-task) and a blank email saved.
  test "requires an email address" do
    user = User.new(password: "a-long-enough-password")

    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "requires a unique email address" do
    User.create!(email_address: "taken@example.com", password: "a-long-enough-password")

    duplicate = User.new(email_address: "taken@example.com", password: "a-long-enough-password")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
    assert_nothing_raised { duplicate.save } # returns false, never raises
  end

  test "uniqueness is case-insensitive via normalization" do
    User.create!(email_address: "taken@example.com", password: "a-long-enough-password")

    duplicate = User.new(email_address: "TAKEN@example.com", password: "a-long-enough-password")

    assert_not duplicate.valid?
  end
end
