class CharacterEntriesController < ApplicationController
  allow_unauthenticated_access

  def show
    @character_entry = CharacterEntry
                       .includes(flashcard_characters: :flashcard)
                       .find(params[:id])
    @flashcard_characters =
      @character_entry.flashcard_characters
                      .sort_by(&:position)
  end
end
