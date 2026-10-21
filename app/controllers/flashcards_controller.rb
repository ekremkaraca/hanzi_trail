class FlashcardsController < ApplicationController
  # Browsing and practice stay public; every write requires a curator.
  # `except:` (not `only:`) so future actions default to gated.
  allow_unauthenticated_access
  before_action :require_authentication, except: %i[index show]
  before_action :set_flashcard, only: %i[show edit update destroy]

  # The index is paginated: one page of cards per request,
  # with the filter parameters carried onto the page links.
  PER_PAGE = 50

  def index
    page = current_page

    # Load one row past the page so the view can offer a
    # "Next" link without a second count query, then hand
    # the page exactly PER_PAGE cards.
    cards = Flashcard
      .all
      .by_source(QueryParam.scalar(params[:source]))
      .by_hsk_level(QueryParam.scalar(params[:hsk_level]))
      .by_category(QueryParam.scalar(params[:category]))
      .with_story_filter(QueryParam.scalar(params[:story_status]))
      .search(QueryParam.scalar(params[:query]))
      .order(:character)
      .limit(PER_PAGE + 1)
      .offset((page - 1) * PER_PAGE)
      .to_a

    @has_more_flashcards = cards.size > PER_PAGE
    @flashcards = cards.first(PER_PAGE)
    @current_page = page
  end

  def show; end

  def new
    authorize! Flashcard
    @flashcard = Flashcard.new
  end

  def edit
    authorize! @flashcard
  end

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

  # Page numbers arrive via the query string, so they are
  # scrubbed like every other untrusted value; anything
  # below 1 (or non-numeric) lands on the first page.
  def current_page
    [ QueryParam.scalar(params[:page]).to_i, 1 ].max
  end

  def set_flashcard
    # QueryParam.scalar keeps an Array/Hash id (?id[]=1) from reaching find,
    # which would otherwise return a collection and 500 downstream.
    @flashcard = Flashcard.find(QueryParam.scalar(params[:id]))
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
