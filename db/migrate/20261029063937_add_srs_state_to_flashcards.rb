class AddSrsStateToFlashcards < ActiveRecord::Migration[8.1]
  # SM-2-lite needs per-card memory of *how fast* intervals should grow.
  # `ease` (1.3..2.5) scales the growth rate, `success_streak` is the
  # exponent: good_interval = 3 days * ease^streak. `difficulty` stays as
  # the informational last rating; its check constraint is untouched.
  def up
    add_column :flashcards, :ease, :float, default: 2.5, null: false
    add_column :flashcards, :success_streak, :integer, default: 0, null: false
    add_check_constraint :flashcards,
      "ease >= 1.3 AND ease <= 2.5",
      name: "flashcards_ease_range"
    add_check_constraint :flashcards,
      "success_streak >= 0",
      name: "flashcards_success_streak_non_negative"

    backfill_from_review_attempts
  end

  def down
    remove_check_constraint :flashcards, name: "flashcards_success_streak_non_negative"
    remove_check_constraint :flashcards, name: "flashcards_ease_range"
    remove_column :flashcards, :success_streak
    remove_column :flashcards, :ease
  end

  private

  # Replay the scheduler's rules over each card's rating history so old
  # cards resume on their real learning curve instead of all restarting
  # at 3 days. Same ease/streak transitions as Review::Scheduler; the
  # interval itself is NOT recomputed, only the two growth inputs.
  # NOTE: lapse handling diverges by design — this replays the original
  # full reset (streak -> 0) while the scheduler now soft-resets
  # (streak - 2). Historical approximation, not a live rule.
  def backfill_from_review_attempts
    Flashcard.find_each do |card|
      ease = 2.5
      streak = 0

      card.review_attempts.order(:reviewed_at).pluck(:rating).each do |rating|
        case rating
        when "again" then ease = [ ease - 0.2, 1.3 ].max; streak = 0
        when "hard"  then ease = [ ease - 0.1, 1.3 ].max
        when "good"  then streak += 1
        when "easy"  then ease = [ ease + 0.1, 2.5 ].min; streak += 1
        end
      end

      # update_columns: pure data repair, no callbacks or validations
      # needed for two derived numbers.
      card.update_columns(ease: ease, success_streak: streak, updated_at: Time.current)
    end
  end
end
