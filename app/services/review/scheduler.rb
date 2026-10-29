module Review
  class Scheduler
    # SM-2-lite: interval = GOOD_BASE * ease^streak, adjusted per rating.
    # Ease (1.3..2.5) is two-way so a card that lapses can climb back;
    # with only decay every long-lived card would sink to the floor.
    GOOD_BASE = 3.days
    EASY_MULT = 1.3
    HARD_DIV = 2.5
    EASE_MIN = 1.3
    EASE_MAX = 2.5
    EASE_DELTA = { "again" => -0.2, "hard" => -0.1, "good" => 0.0, "easy" => +0.1 }.freeze
    # Cap so mature cards stay reachable; floor so hard/again can never
    # schedule inside the same minute at minimum ease.
    INTERVAL_CAP = 180.days
    INTERVAL_FLOOR = 10.minutes

    attr_reader :flashcard, :rating

    def initialize(flashcard:, rating:)
      @flashcard = flashcard
      @rating = rating
    end

    def call
      raise ArgumentError, "Invalid rating" unless Flashcard::REVIEW_RATINGS.include?(rating)

      flashcard.with_lock do
        # Not-due check inside the lock prevents double-review races.
        raise Flashcard::CardNotDueError unless flashcard.next_review_at <= Time.current

        reviewed_at = Time.current
        state = next_state

        flashcard.update!(
          difficulty: rating,
          ease: state[:ease],
          success_streak: state[:streak],
          review_count: flashcard.review_count + 1,
          next_review_at: state[:next_review_at]
        )

        # Audit row in the same transaction as the state change.
        flashcard.review_attempts.create!(rating: rating, reviewed_at: reviewed_at)
      end
    end

    private

    # All interval math keys off the PRE-update streak: incrementing
    # first would make the first-ever Good jump to 7.5d instead of 3d.
    # The streak increment only affects the *next* interval.
    def next_state
      new_ease = clamp_ease(flashcard.ease + EASE_DELTA.fetch(rating))
      new_streak =
        case rating
        # A lapse soft-resets: mature cards keep most of their curve
        # (streak - 2) so one slip doesn't drop a 180d card back to a
        # 3d next-Good and re-flood the queue with known words.
        when "again" then [ flashcard.success_streak - 2, 0 ].max
        # Hard means growth *pauses* (ease penalty + division shrink
        # the interval), so pressing Hard repeatedly must shrink, not
        # compound.
        when "hard" then flashcard.success_streak
        else flashcard.success_streak + 1
        end

      { ease: new_ease, streak: new_streak, next_review_at: next_interval(new_ease).since(Time.current) }
    end

    def next_interval(new_ease)
      # Relearn bypasses the floor: it must stay 1 minute, the clamp is
      # only there to keep hard/above-minimum-ease values sane.
      return 1.minute if rating == "again"

      raw = GOOD_BASE * (new_ease**flashcard.success_streak) * RATING_FACTOR.fetch(rating)
      [ [ raw, INTERVAL_CAP ].min, INTERVAL_FLOOR ].max
    end

    # good divides by nothing (factor 1), hard shrinks, easy rewards.
    RATING_FACTOR = { "hard" => 1 / HARD_DIV, "good" => 1.0, "easy" => EASY_MULT }.freeze

    def clamp_ease(value)
      [ [ value, EASE_MIN ].max, EASE_MAX ].min
    end
  end
end
