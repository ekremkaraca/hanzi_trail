require "test_helper"

class CharacterEntryPolicyTest < ActiveSupport::TestCase
  setup do
    @entry = character_entries(:one)
  end

  test "anyone can view an entry" do
    assert permitted?(:show?, user: nil)
    assert permitted?(:show?, user: users(:one))
  end

  test "only curators may edit or delete" do
    assert_not permitted?(:update?, user: nil)
    assert_not permitted?(:destroy?, user: nil)
    assert permitted?(:update?, user: users(:one))
    assert permitted?(:destroy?, user: users(:one))
  end

  private

  def permitted?(rule, user:)
    CharacterEntryPolicy.new(@entry, user: user).apply(rule)
  end
end
