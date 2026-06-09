require "test_helper"

class ReviewVelocityTest < ActiveSupport::TestCase
  test "returns zero when there are no review attempts" do
    ReviewAttempt.delete_all

    assert_equal 0, ReviewVelocity.call
  end

  test "calculates average reviews per active day" do
    ReviewAttempt.delete_all

    card = flashcards(:network)

    2.times do
      ReviewAttempt.create!(flashcard: card, rating: "good", reviewed_at: Time.current)
    end

    ReviewAttempt.create!(flashcard: card, rating: "hard", reviewed_at: 1.day.ago)

    assert_equal 1.5, ReviewVelocity.call
  end
end
