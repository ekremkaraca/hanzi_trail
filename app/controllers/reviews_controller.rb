class ReviewsController < ApplicationController
  def show
    # Let users restart the per-filter progress counter from the empty state.
    reset_reviewed_count if params[:reset_session] == "1"

    # Queue owns filter-aware card selection; the controller only exposes view data.
    @review_queue = Review::Queue.new(
      filters: filter_params,
      session: session
    )

    @flashcard = @review_queue.next_card
    @remaining_due_count = @review_queue.remaining_count
    @empty_state_title = empty_state_title
    @reviewed_count = reviewed_count
    @review_filter_params = filter_params
    @total_review_count = @reviewed_count + @remaining_due_count
    @reviewed_today_count = ReviewAttempt.today.count

    # Preserve the active review URL for "back to review" links on card pages.
    session[:review_return_to] = @flashcard.present? ? request.fullpath : nil
  end

  def update
    rating = review_params[:rating]

    # Keep invalid input as a redirect instead of surfacing a 500 from the service.
    unless Flashcard::REVIEW_RATINGS.include?(rating)
      return redirect_to review_path, alert: "Invalid review rating."
    end

    # Find through the queue scope so filtered review URLs cannot rate outside cards.
    flashcard = Review::Queue.new(filters: filter_params, session: session)
      .scope
      .find(params[:flashcard_id])

    # Scheduler owns the locked mutation and review-attempt side effect.
    Review::Scheduler.new(
      flashcard: flashcard,
      rating: rating
    ).call

    # Count only successful reviews in the current filter-specific session.
    increment_reviewed_count

    redirect_to review_path(filter_params), notice: "Review saved."
  rescue Flashcard::CardNotDueError
    redirect_to review_path(filter_params),
      alert: "This card is not due for review."
  rescue ActiveRecord::RecordNotFound
    redirect_to review_path(filter_params),
      alert: "That card is not in the current review filter."
  end

  def preferences
    session[:show_pinyin] = params[:show_pinyin] == "1"

    redirect_to review_path(filter_params)
  end

  private

  def review_params
    { rating: params.dig(:review, :rating) }
  end

  # Single source of truth for the three filter keys used in redirects and
  # session keys. Blank values are dropped so e.g. ?source= and an absent
  # source produce the same review_path URL.
  def filter_params
    Review::FilterParams.from(params)
  end

  def empty_state_title
    return "No HSK cards are due right now." if params[:source] == "hsk"
    return "No curated cards are due right now." if params[:source] == "curated"
    return "No missing-story cards are due right now." if params[:story_status] == "missing"
    return "No #{category_label} cards are due right now." if params[:category].present?

    "No cards due right now."
  end

  def category_label
    params[:category].to_s.humanize.downcase
  end

  def review_scope
    Flashcard
        .by_source(params[:source])
        .by_category(params[:category])
        .with_story_filter(params[:story_status])
  end

  def review_session_key
    # Use the shared filter module so the session key is built from the
    # same three keys the helper and redirect use.
    filter_params
      .sort
      .map { |k, v| "#{k}=#{v}" }
      .join("&")
      .presence || "all"
  end

  def reviewed_count
    session[:review_sessions] ||= {}
    session[:review_sessions][review_session_key].to_i
  end

  def increment_reviewed_count
    session[:review_sessions] ||= {}
    session[:review_sessions][review_session_key] = reviewed_count + 1
  end

  def reset_reviewed_count
    session[:review_sessions] ||= {}
    session[:review_sessions][review_session_key] = 0
  end
end
