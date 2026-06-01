class AddCheckConstraints < ActiveRecord::Migration[8.1]
  def up
    add_check_constraint :flashcards, "source IN ('curated', 'hsk')", name: "flashcards_source_check"
    add_check_constraint :flashcards, "difficulty IN ('new', 'again', 'easy', 'good', 'hard')", name: "flashcards_difficulty_check"
    add_check_constraint :flashcards, "story_status IN ('missing', 'draft', 'curated')", name: "flashcards_story_status_check"
    add_check_constraint :flashcards, "review_count >= 0", name: "flashcards_review_count_check"
    add_check_constraint :review_attempts, "rating IN ('again', 'easy', 'good', 'hard')", name: "review_attempts_rating_check"
  end

  def down
    remove_check_constraint :flashcards, name: "flashcards_source_check"
    remove_check_constraint :flashcards, name: "flashcards_difficulty_check"
    remove_check_constraint :flashcards, name: "flashcards_story_status_check"
    remove_check_constraint :flashcards, name: "flashcards_review_count_check"
    remove_check_constraint :review_attempts, name: "review_attempts_rating_check"
  end
end
