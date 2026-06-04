class CharacterEntriesController < ApplicationController
  def show
    @character_entry = CharacterEntry.includes(
      flashcards: {
        flashcard_characters: :character_entry
      }
    ).find(params[:id])
    @flashcards = @character_entry.flashcards.order(:character).limit(20)
    @related_character_entries = CharacterEntry.joins(
      flashcard_characters: :flashcard
    ).where(
      flashcard_characters: {
        flashcard_id: @character_entry.flashcards.select(:id)
      }
    ).where.not(
      id: @character_entry.id
    ).distinct.order(:character).limit(20)

    @flashcard_characters =
      @character_entry.flashcard_characters
                      .includes(:flashcard)
                      .order(:position)
  end
end
