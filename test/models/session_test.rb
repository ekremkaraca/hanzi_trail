# test/models/session_test.rb
require "test_helper"

class SessionTest < ActiveSupport::TestCase
  # Covers the exact query the recurring purge task (and `rake
  # sessions:purge`) runs: expired rows go, active rows stay.
  test "the purge scope deletes only expired sessions" do
    expired = users(:one).sessions.create!(expires_at: 1.minute.ago)
    live = users(:one).sessions.create!(expires_at: Session::SESSION_TTL.from_now)

    # delete_all returns the number of rows removed, not their ids.
    assert_equal 1, Session.expired.delete_all
    assert_nil Session.find_by(id: expired.id)
    assert Session.find_by(id: live.id)
  end
end
