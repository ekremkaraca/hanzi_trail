class FlashcardsController < ApplicationController
  # Review updates remain enabled for the local MVP because review is the core flow.
  # Flashcard CRUD is disabled until authentication exists.
  before_action :require_write_access, only: %i[new edit create update destroy]
  before_action :set_flashcard, only: %i[show edit update destroy]

  def index
    @flashcards = Flashcard.order(:character)
    @flashcards = @flashcards.by_source(params[:source])
    @flashcards = @flashcards.by_hsk_level(params[:hsk_level])
    @flashcards = @flashcards.by_category(params[:category])
    @flashcards = apply_story_filter(@flashcards)
    @flashcards = @flashcards.search(params[:query])
  end

  def show; end

  def new
    @flashcard = Flashcard.new
  end

  def edit; end

  def create
    @flashcard = Flashcard.new(flashcard_params)

    if @flashcard.save
      redirect_to @flashcard, notice: "Flashcard was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @flashcard.update(flashcard_params)
      redirect_to @flashcard, notice: "Flashcard was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @flashcard.destroy
    redirect_to flashcards_url, notice: "Flashcard was successfully destroyed."
  end

  private

  def set_flashcard
    @flashcard = Flashcard.find(params[:id])
  end

  def apply_story_filter(scope)
    case params[:story_status]
    when "short"
      scope.short_story
    when *Flashcard::STORY_STATUSES
      scope.by_story_status(params[:story_status])
    else
      scope
    end
  end

  def flashcard_params
    params
      .require(:flashcard)
      .permit(
        :character,
        :pinyin,
        :meaning,
        :story,
        :category,
        :components,
        :literal_meaning,
        :mnemonic,
        :usage_note
      )
  end
end
