# test/controllers/flashcards_controller_test.rb

require "test_helper"

class FlashcardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @flashcard = flashcards(:one)
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
end
