# test/controllers/reviews_controller_test.rb

require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Flashcard.update_all(next_review_at: 1.day.from_now)

    @flashcard = flashcards(:network)
    @flashcard.update!(next_review_at: 1.minute.ago)
  end

  test "should show review page" do
    get review_url

    assert_response :success
    assert_select "h1", "Review"
    assert_includes response.body, @flashcard.character
  end

  test "should update flashcard review state" do
    assert_difference -> { @flashcard.reload.review_count }, 1 do
      patch review_flashcard_url(@flashcard), params: {
        review: { rating: "good" }
      }
    end

    assert_redirected_to review_url
    assert_equal "good", @flashcard.reload.difficulty
    assert_operator @flashcard.next_review_at, :>, Time.current
  end

  test "should redirect on invalid rating" do
    patch review_flashcard_url(@flashcard), params: {
      review: { rating: "invalid" }
    }

    assert_redirected_to review_url
  end
  test "show displays remaining due count" do
    Flashcard.update_all(next_review_at: 1.day.from_now)
    flashcards(:network).update!(next_review_at: 1.minute.ago)
    flashcards(:hsk_one).update!(next_review_at: 2.minutes.ago)

    get review_url

    assert_response :success
    assert_includes response.body, "Cards remaining: 2"
  end
  test "show displays shortcut hints" do
    Flashcard.update_all(next_review_at: 1.day.from_now)
    flashcards(:network).update!(next_review_at: 1.minute.ago)

    get review_url

    assert_response :success
    assert_includes response.body, "Again [1]"
    assert_includes response.body, "Hard [2]"
    assert_includes response.body, "Good [3]"
    assert_includes response.body, "Easy [4]"
  end

  test "show wires keyboard shortcut handler" do
    get review_url

    assert_response :success
    assert_includes response.body, "keydown@window->review#handleKeydown"
    assert_includes response.body, "data-review-target=\"showButton\""
  end

  test "show renders review buttons that submit ratings to due card" do
    Flashcard.update_all(next_review_at: 1.day.from_now)
    flashcards(:network).update!(next_review_at: 1.minute.ago)

    get review_url

    assert_response :success
    assert_select "form[action=?][method=post]", review_flashcard_path(flashcards(:network)) do
      assert_select "input[name=_method][value=patch]", 4
      assert_select "input[name='review[rating]'][value=again]", 1
      assert_select "input[name='review[rating]'][value=hard]", 1
      assert_select "input[name='review[rating]'][value=good]", 1
      assert_select "input[name='review[rating]'][value=easy]", 1
    end
  end

  test "show displays empty state when no cards are due" do
    Flashcard.update_all(next_review_at: 1.day.from_now)

    get review_url

    assert_response :success
    assert_includes response.body, "No cards due right now"
    assert_select "a[href=?]", flashcards_path, text: "Browse flashcards"
  end
end
