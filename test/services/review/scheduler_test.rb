require "test_helper"

module Review
  class SchedulerTest < ActiveSupport::TestCase
    setup do
      @flashcard = flashcards(:network)
      @initial_review_count = @flashcard.review_attempts.count
    end

    test "call successfully updates the flashcard and creates a review attempt" do
      scheduler = Review::Scheduler.new(flashcard: @flashcard, rating: "good")

      # Freeze time so we can precisely test the timestamp update
      freeze_time do
        assert_difference("ReviewAttempt.count", 1) do
          scheduler.call
        end

        @flashcard.reload

        # Verify the flashcard was pushed into the future
        assert @flashcard.next_review_at > Time.current

        # Verify the attempt was logged correctly
        latest_attempt = @flashcard.review_attempts.last
        assert_equal "good", latest_attempt.rating
      end
    end

    test "call rolls back everything if creating the review attempt fails" do
      scheduler = Review::Scheduler.new(flashcard: @flashcard, rating: "good")

      original_due_date = @flashcard.next_review_at
      invalid_attempt = ReviewAttempt.new(flashcard: @flashcard, rating: "good")
      failing_attempts = Object.new
      failing_attempts.define_singleton_method(:create!) do |**|
        raise ActiveRecord::RecordInvalid, invalid_attempt
      end

      # Replace only this instance's association writer to simulate an audit-row failure.
      @flashcard.define_singleton_method(:review_attempts) { failing_attempts }

      # Ensure neither the Flashcard nor the ReviewAttempt is saved
      assert_no_difference("ReviewAttempt.count") do
        assert_raises(ActiveRecord::RecordInvalid) do
          scheduler.call
        end
      end

      @flashcard.reload
      assert_equal original_due_date, @flashcard.next_review_at
    end

    test "call rejects invalid ratings before mutating review state" do
      scheduler = Review::Scheduler.new(flashcard: @flashcard, rating: "invalid_rating")
      original_due_date = @flashcard.next_review_at

      assert_no_difference("ReviewAttempt.count") do
        # Invalid ratings are input errors, not transaction rollback scenarios.
        assert_raises(ArgumentError) do
          scheduler.call
        end
      end

      @flashcard.reload
      assert_equal original_due_date, @flashcard.next_review_at
    end

    test "first-ever good schedules 3 days and starts the streak at 1" do
      flashcard = fresh_due_card
      scheduler = Review::Scheduler.new(flashcard: flashcard, rating: "good")

      scheduler.call
      flashcard.reload

      # Interval keys off the PRE-update streak, so the first Good is the base.
      assert_equal 3.days.from_now.to_i, flashcard.next_review_at.to_i
      assert_equal 1, flashcard.success_streak
      assert_equal 2.5, flashcard.ease
    end

    test "consecutive goods grow the interval 7.5d then 18.7d" do
      freeze_time do
        flashcard = fresh_due_card

        Review::Scheduler.new(flashcard: flashcard, rating: "good").call
        # +1.minute slack so the not-due guard never trips on rounding.
        travel_to 3.days.from_now + 1.minute
        Review::Scheduler.new(flashcard: flashcard.reload, rating: "good").call
        flashcard.reload
        assert_in_delta 7.5.days, flashcard.next_review_at - Time.current, 1.minute

        travel_to flashcard.next_review_at + 1.minute
        Review::Scheduler.new(flashcard: flashcard.reload, rating: "good").call
        flashcard.reload
        assert_in_delta 18.75.days, flashcard.next_review_at - Time.current, 1.minute
      end
    end

    test "again soft-resets the streak and floors ease descent" do
      freeze_time do
        flashcard = fresh_due_card(ease: 1.35, success_streak: 4)
        Review::Scheduler.new(flashcard: flashcard, rating: "again").call
        flashcard.reload

        # Relearn is always the same minute; the lapse costs two streak
        # steps, not the whole curve.
        assert_equal 1.minute.from_now.to_i, flashcard.next_review_at.to_i
        assert_equal 2, flashcard.success_streak
        assert_equal 1.3, flashcard.ease.round(2)
      end
    end

    test "a mature card keeps most of its interval growth through lapses" do
      freeze_time do
        flashcard = fresh_due_card(success_streak: 4)

        # First lapse: streak 4 -> 2 and ease 2.5 -> 2.3, so the next Good
        # is 3d * 2.3^2, meaningfully above a fresh card's 3d.
        Review::Scheduler.new(flashcard: flashcard, rating: "again").call
        travel_to flashcard.reload.next_review_at + 1.minute
        Review::Scheduler.new(flashcard: flashcard.reload, rating: "good").call
        flashcard.reload
        assert_in_delta 3.days * (2.3**2), flashcard.next_review_at - Time.current, 1.minute
        assert_equal 3, flashcard.success_streak

        # Second lapse from streak 3: 3 -> 1, ease 2.3 -> 2.1 (again is
        # -0.2), still not fully reset.
        travel_to flashcard.next_review_at + 1.minute
        Review::Scheduler.new(flashcard: flashcard.reload, rating: "again").call
        travel_to flashcard.reload.next_review_at + 1.minute
        Review::Scheduler.new(flashcard: flashcard.reload, rating: "good").call
        flashcard.reload
        assert_in_delta 3.days * 2.1, flashcard.next_review_at - Time.current, 1.minute
        assert_equal 2, flashcard.success_streak

        # Repeated lapses bottom out at 0 without going negative.
        travel_to flashcard.next_review_at + 1.minute
        Review::Scheduler.new(flashcard: flashcard.reload, rating: "again").call
        flashcard.reload
        assert_equal 0, flashcard.success_streak
      end
    end

    test "hard freezes the streak and shrinks the interval" do
      freeze_time do
        flashcard = fresh_due_card(success_streak: 2)
        Review::Scheduler.new(flashcard: flashcard, rating: "hard").call
        flashcard.reload

        # Interval keys off the NEW ease: 3d * 2.4^2 / 2.5 ~= 6.9d.
        # The streak must not have advanced.
        expected = 3.days * (2.4**2) / 2.5
        assert_in_delta expected, flashcard.next_review_at - Time.current, 1.minute
        assert_equal 2, flashcard.success_streak
        assert_equal 2.4, flashcard.ease.round(2)
      end
    end

    test "easy at streak zero stays under 4 days" do
      freeze_time do
        flashcard = fresh_due_card(ease: 2.4)
        Review::Scheduler.new(flashcard: flashcard, rating: "easy").call
        flashcard.reload

        # 3d * 1.3 = 3.9d with the multiplier applied to the base streak.
        assert_in_delta 3.9.days, flashcard.next_review_at - Time.current, 1.minute
        assert_equal 1, flashcard.success_streak
        assert_equal 2.5, flashcard.ease.round(2)
      end
    end

    test "intervals cap at 180 days while the streak keeps growing" do
      freeze_time do
        flashcard = fresh_due_card(ease: 2.5, success_streak: 10)
        Review::Scheduler.new(flashcard: flashcard, rating: "good").call
        flashcard.reload

        # 3d * 2.5^10 = ~29,000d unbounded; capped, but streak still advances.
        assert_equal 180.days.from_now.to_i, flashcard.next_review_at.to_i
        assert_equal 11, flashcard.success_streak
      end
    end

    test "ease recovers toward 2.5 through sustained easy presses" do
      freeze_time do
        flashcard = fresh_due_card(ease: 1.3)

        Review::Scheduler.new(flashcard: flashcard, rating: "easy").call
        flashcard.reload
        assert_equal 1.4, flashcard.ease.round(2)

        # Ceiling: 2.45 + 0.1 clamps at 2.5, never past it.
        ceiling_card = fresh_due_card(ease: 2.45)
        Review::Scheduler.new(flashcard: ceiling_card, rating: "easy").call
        ceiling_card.reload
        assert_equal 2.5, ceiling_card.ease
      end
    end

    private

    # A never-reviewed, due-now card bypassing fixtures so each test sets
    # exactly the SRS state it exercises.
    def fresh_due_card(ease: 2.5, success_streak: 0)
      Flashcard.create!(
        character: "测#{rand(1_000_000)}",
        pinyin: "cè",
        meaning: "test card",
        ease: ease,
        success_streak: success_streak
      )
    end
  end
end
