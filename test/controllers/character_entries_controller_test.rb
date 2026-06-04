require "test_helper"

class CharacterEntriesControllerTest < ActionDispatch::IntegrationTest
  test "should show character entry" do
    entry = character_entries(:one)

    get character_entry_path(entry)

    assert_response :success
    assert_select "h1", text: "网"
  end

  test "shows related flashcards for character entry" do
    card = Flashcard.create!(
      character: "网络",
      pinyin: "wǎngluò",
      meaning: "network"
    )

    CharacterLinker.call(card)
    entry = CharacterEntry.find_by!(character: "网")

    get character_entry_path(entry)

    assert_response :success
    assert_select "a[href=?]", flashcard_path(card), text: /网络/
  end

  test "flashcard show links to character entries" do
    card = Flashcard.create!(
      character: "网络",
      pinyin: "wǎngluò",
      meaning: "network"
    )

    CharacterLinker.call(card)

    get flashcard_path(card)

    assert_response :success
    assert_select "a[href=?]", character_entry_path(CharacterEntry.find_by!(character: "网"))
  end
end
