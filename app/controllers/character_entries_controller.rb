class CharacterEntriesController < ApplicationController
  allow_unauthenticated_access
  before_action :require_authentication, except: %i[show]
  before_action :set_character_entry, only: %i[show edit update destroy]

  def show
    @flashcard_characters =
      @character_entry.flashcard_characters
                      .includes(:flashcard)
                      .sort_by(&:position)
  end

  def edit
    authorize! @character_entry
  end

  def update
    authorize! @character_entry

    if @character_entry.update(character_entry_params)
      redirect_to @character_entry, notice: "Character was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! @character_entry

    # Refuse to delete an entry any card still needs: the card's character list
    # is derived from its character string and would be corrupted with no way to
    # repair it (see CharacterEntry#deletable?).
    unless @character_entry.deletable?
      return redirect_to @character_entry,
        alert: "#{@character_entry.character} is still part of " \
               "#{@character_entry.required_by_cards.count} card(s); " \
               "delete or edit those cards first."
    end

    @character_entry.destroy
    redirect_to flashcards_path, notice: "Character was successfully deleted."
  end

  private

  def set_character_entry
    @character_entry = CharacterEntry
                       .includes(flashcard_characters: :flashcard)
                       .find(params[:id])
  end

  def character_entry_params
    params
      .require(:character_entry)
      .permit(:pinyin, :meaning, :radical, :notes)
  end
end
