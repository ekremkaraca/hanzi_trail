require "test_helper"

class CharacterEntryTest < ActiveSupport::TestCase
  test "requires character" do
    entry = CharacterEntry.new(character: "")

    assert_not entry.valid?
  end

  test "requires unique character" do
    CharacterEntry.create!(character: "河")

    duplicate = CharacterEntry.new(character: "河")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:character], "has already been taken"
  end
end
