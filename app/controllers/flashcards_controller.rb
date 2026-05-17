class FlashcardsController < ApplicationController
  before_action :set_flashcard, only: %i[show edit update destroy]

  def index
    @flashcards = Flashcard
      .by_source(params[:source])
      .by_hsk_level(params[:hsk_level])
      .by_category(params[:category])
      .by_story_status(params[:story_status])
      .order(:character)
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

  def flashcard_params
    params
      .require(:flashcard)
      .permit(
        :character,
        :pinyin,
        :meaning,
        :story,
        :category
      )
  end
end
