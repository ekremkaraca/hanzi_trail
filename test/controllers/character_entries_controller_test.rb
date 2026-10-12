require "test_helper"

class CharacterEntriesControllerTest < ActionDispatch::IntegrationTest
  test "should show character entry" do
    entry = character_entries(:one)

    get character_entry_path(entry)

    assert_response :success
    assert_select "h1", text: "网"
  end

  test "shows related flashcards for character entry" do
    # The Flashcard after_save relink callback creates the entries/joins.
    card = Flashcard.create!(
      character: "网络",
      pinyin: "wǎngluò",
      meaning: "network"
    )

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

    get flashcard_path(card)

    assert_response :success
    assert_select "a[href=?]", character_entry_path(CharacterEntry.find_by!(character: "网"))
  end

  test "entry write actions redirect anonymous visitors to sign-in" do
    entry = character_entries(:one)

    get edit_character_entry_path(entry)
    assert_redirected_to new_session_path

    patch character_entry_path(entry), params: { character_entry: { pinyin: "wǎng" } }
    assert_redirected_to new_session_path
    assert_nil entry.reload.pinyin

    assert_no_difference("CharacterEntry.count") do
      delete character_entry_path(entry)
    end
    assert_redirected_to new_session_path
  end

  test "curator sees edit and delete affordances on entry page" do
    sign_in_as users(:one)

    get character_entry_path(character_entries(:one))

    assert_response :success
    assert_select "a[href=?]", edit_character_entry_path(character_entries(:one)), text: "Edit character"
  end

  test "anonymous visitors do not see edit affordances on entry page" do
    get character_entry_path(character_entries(:one))

    assert_select "a[href=?]", edit_character_entry_path(character_entries(:one)), count: 0
  end

  test "curator edits and updates a character entry" do
    sign_in_as users(:one)
    entry = character_entries(:one)

    get edit_character_entry_path(entry)
    assert_response :success

    patch character_entry_path(entry), params: {
      character_entry: {
        pinyin: "wǎng",
        meaning: "net; web",
        radical: "糸 (58)",
        notes: "Silk threads woven into a net."
      }
    }

    assert_redirected_to character_entry_path(entry)
    entry.reload
    assert_equal "wǎng", entry.pinyin
    assert_equal "糸 (58)", entry.radical
    assert_equal "Silk threads woven into a net.", entry.notes
  end

  test "update keeps the character identity untouched" do
    sign_in_as users(:one)
    entry = character_entries(:one)

    patch character_entry_path(entry), params: {
      character_entry: { character: "换", pinyin: "wǎng" }
    }

    assert_response :redirect
    assert_equal "网", entry.reload.character
  end

  test "curator destroys a character entry and unlinks cards" do
    sign_in_as users(:one)
    entry = character_entries(:one)
    card = flashcards(:network)

    # Fixtures bypass callbacks, so wire the join explicitly.
    card.flashcard_characters.create!(character_entry: entry, position: 0)

    assert_difference("CharacterEntry.count", -1) do
      delete character_entry_path(entry)
    end

    assert_redirected_to flashcards_path
    assert card.reload.persisted?, "the flashcard itself must survive"
    assert_empty card.reload.character_entries
  end
end
