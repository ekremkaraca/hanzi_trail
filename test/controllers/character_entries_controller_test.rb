require "test_helper"

class CharacterEntriesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get character_entry_path(character_entries(:one))

    assert_response :success
  end

  test "shows character entry" do
    entry = CharacterEntry.create!(
      character: "测",
      meaning: "net"
    )

    get character_entry_path(entry)

    assert_response :success
  end
end
