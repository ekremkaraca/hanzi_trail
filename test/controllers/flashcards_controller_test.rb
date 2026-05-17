# test/controllers/flashcards_controller_test.rb

require "test_helper"

class FlashcardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @flashcard = flashcards(:network)
  end

  test "should get index" do
    get flashcards_url
    assert_response :success
  end

  test "should get new" do
    get new_flashcard_url
    assert_response :success
  end

  test "should create flashcard" do
    assert_difference("Flashcard.count", 1) do
      post flashcards_url, params: {
        flashcard: {
          character: "北京",
          pinyin: "Běijīng",
          meaning: "Beijing",
          story: "北 means north; 京 means capital.",
          category: "cities"
        }
      }
    end

    assert_redirected_to flashcard_url(Flashcard.last)
  end

  test "should show flashcard" do
    get flashcard_url(@flashcard)
    assert_response :success
  end

  test "should get edit" do
    get edit_flashcard_url(@flashcard)
    assert_response :success
  end

  test "should update flashcard" do
    patch flashcard_url(@flashcard), params: {
      flashcard: {
        meaning: "network / web"
      }
    }

    assert_redirected_to flashcard_url(@flashcard)
    assert_equal "network / web", @flashcard.reload.meaning
  end

  test "should destroy flashcard" do
    assert_difference("Flashcard.count", -1) do
      delete flashcard_url(@flashcard)
    end

    assert_redirected_to flashcards_url
  end

  test "index shows all flashcards by default" do
    get flashcards_path

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:network).character
    assert_select ".flashcard-character-link", text: flashcards(:algorithm).character
  end

  test "index filters by source" do
    get flashcards_path, params: { source: "hsk" }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
    assert_select ".flashcard-character-link", text: flashcards(:network).character, count: 0
  end

  test "index filters by hsk level" do
    get flashcards_path, params: { hsk_level: "old-1" }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
    assert_select ".flashcard-character-link", text: flashcards(:network).character, count: 0
  end

  test "index filters by category" do
    get flashcards_path, params: { category: "technical" }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:network).character
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character, count: 0
  end

  test "index shows clear filters link" do
    get flashcards_path, params: { source: "hsk" }

    assert_response :success
    assert_select "a[href=?]", flashcards_path, text: "Clear"
  end

  test "index all-empty filter query shows all flashcards" do
    get flashcards_path, params: {
      source: "",
      hsk_level: "",
      category: "",
      story_status: "",
      commit: "Filter"
    }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:network).character
    assert_select ".flashcard-character-link", text: flashcards(:algorithm).character
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
  end

  test "index filters by story status" do
    flashcards(:network).update!(story_status: "curated")
    flashcards(:hsk_one).update!(story_status: "missing")

    get flashcards_path, params: { story_status: "missing" }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
    assert_select ".flashcard-character-link", text: flashcards(:network).character, count: 0
  end

  test "index shows story status badge" do
    flashcards(:network).update!(story_status: "curated")

    get flashcards_path

    assert_response :success
    assert_includes response.body, "Curated story"
  end
end
