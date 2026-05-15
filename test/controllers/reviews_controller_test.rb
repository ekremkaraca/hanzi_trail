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
end
