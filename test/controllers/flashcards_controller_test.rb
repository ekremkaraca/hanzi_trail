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
    assert_redirected_to flashcards_path
    assert_equal "Editing is disabled until authentication is added", flash[:alert]
  end

  test "should create flashcard" do
    assert_no_difference("Flashcard.count") do
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

    assert_redirected_to flashcards_path
    assert_equal "Editing is disabled until authentication is added", flash[:alert]
  end

  test "should show flashcard" do
    get flashcard_url(@flashcard)
    assert_response :success
  end

  test "should get edit" do
    get edit_flashcard_url(@flashcard)
    assert_redirected_to flashcards_path
    assert_equal "Editing is disabled until authentication is added", flash[:alert]
  end

  test "should update flashcard" do
    patch flashcard_url(@flashcard), params: {
      flashcard: {
        meaning: "network / web"
      }
    }

    assert_redirected_to flashcards_path
    assert_equal "Editing is disabled until authentication is added", flash[:alert]
    assert_not_equal "network / web", @flashcard.reload.meaning
  end

  test "should destroy flashcard" do
    assert_no_difference("Flashcard.count") do
      delete flashcard_url(@flashcard)
    end

    assert_redirected_to flashcards_url
    assert_equal "Editing is disabled until authentication is added", flash[:alert]
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

  test "index filters by search query" do
    get flashcards_path, params: { query: "network" }
    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:network).character
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character, count: 0
  end

  test "index combines search query and source filter" do
    flashcards(:network).update!(source: "curated")
    flashcards(:hsk_one).update!(source: "hsk", meaning: "network practice")

    get flashcards_path, params: {
      query: "network",
      source: "hsk"
    }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
    assert_select ".flashcard-character-link", text: flashcards(:network).character, count: 0
  end

  test "index shows missing stories shortcut" do
    get flashcards_path

    assert_response :success
    assert_select "a[href=?]", flashcards_path(story_status: "missing"), text: "Missing stories"
  end

  test "index filters by missing story status" do
    flashcards(:network).update!(story_status: "curated")
    flashcards(:hsk_one).update!(story_status: "missing")

    get flashcards_path, params: { story_status: "missing" }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
    assert_select ".flashcard-character-link", text: flashcards(:network).character, count: 0
  end

  test "index shows empty state when filters match no flashcards" do
    get flashcards_path, params: { query: "nonexistent-query" }

    assert_response :success
    assert_includes response.body, "No flashcards matched your filters"
    assert_select "a[href=?]", flashcards_path, text: "Clear filters"
  end

  test "create is disabled without authentication" do
    assert_no_difference "Flashcard.count" do
      post flashcards_path, params: {
        flashcard: {
          character: "测",
          pinyin: "cè",
          meaning: "test"
        }
      }
    end

    assert_redirected_to flashcards_path
    assert_equal "Editing is disabled until authentication is added", flash[:alert]
  end

  test "update is disabled without authentication" do
    patch flashcard_path(@flashcard), params: {
      flashcard: {
        meaning: "updated meaning"
      }
    }

    assert_redirected_to flashcards_path
    assert_equal "Editing is disabled until authentication is added", flash[:alert]
    assert_not_equal "updated meaning", @flashcard.reload.meaning
  end
end
