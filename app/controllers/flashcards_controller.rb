class FlashcardsController < ApplicationController
  # Browsing and practice stay public; every write requires a curator.
  # `except:` (not `only:`) so future actions default to gated.
  allow_unauthenticated_access
  before_action :require_authentication, except: %i[index show]
  before_action :set_flashcard, only: %i[show edit update destroy]

  FLASHCARDS_LIMIT = 200.freeze

  def index
    @flashcards = Flashcard
      .all
      .by_source(params[:source])
      .by_hsk_level(params[:hsk_level])
      .by_category(params[:category])
      .with_story_filter(params[:story_status])
      .search(params[:query])
      .order(:character)
      .limit(FLASHCARDS_LIMIT)
  end

  def show; end

  def new
    authorize! Flashcard
    @flashcard = Flashcard.new
  end

  def edit; end

  def create
    authorize! Flashcard

    @flashcard = Flashcard.new(flashcard_params)

    if @flashcard.save
      redirect_to @flashcard, notice: "Flashcard was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize! @flashcard

    if @flashcard.update(flashcard_params)
      redirect_to @flashcard, notice: "Flashcard was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! @flashcard

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
        :category,
        :components,
        :literal_meaning,
        :mnemonic,
        :usage_note
      )
  end
end
