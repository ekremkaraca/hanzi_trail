require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  test "shows review stats" do
    get stats_url

    assert_response :success
  end

  test "shows rating breakdown" do
    ReviewAttempt.create!(
      flashcard: flashcards(:network),
      rating: "good"
    )

    get stats_url

    assert_response :success
  end
end
