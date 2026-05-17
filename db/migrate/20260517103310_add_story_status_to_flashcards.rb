class AddStoryStatusToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_column :flashcards, :story_status, :string, null: false, default: "missing"
  end
end
