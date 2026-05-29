class ReviewsController < ApplicationController
  def show
    reset_reviewed_count if params[:reset_session] == "1"

    queue = ReviewQueue.new(scope: review_scope)

    @flashcard = queue.next_card
    @remaining_due_count = queue.remaining_count
    @empty_state_title = empty_state_title
    @reviewed_count = reviewed_count
    @review_filter_params = review_params_for_redirect
    @total_review_count = @reviewed_count + @remaining_due_count
    @reviewed_today_count = ReviewAttempt.today.count
  end

  def update
    flashcard = review_scope
      .due_for_review
      .find(params[:flashcard_id])

    flashcard.schedule_next_review!(review_params[:rating])

    increment_reviewed_count

    redirect_to review_path(review_params_for_redirect), notice: "Review saved."
  rescue Flashcard::CardNotDueError
    redirect_to review_path(review_params_for_redirect), alert: "This card is not due for review."
  rescue ArgumentError
    redirect_to review_path(review_params_for_redirect), alert: "Invalid review rating."
  rescue ActionController::ParameterMissing
    redirect_to review_path(review_params_for_redirect), alert: "Missing review parameters."
  end

  def preferences
    session[:show_pinyin] = params[:show_pinyin] == "1"

    redirect_to review_path
  end

  private

  def review_params
    params.require(:review).permit(:rating)
  end

  def review_params_for_redirect
    params.slice(:source, :category, :story_status)
          .permit(:source, :category, :story_status)
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
        .by_story_status(params[:story_status])
  end

  def review_session_key
    sorted = review_params_for_redirect
      .to_h
      .select { |_, v| v.present? }
      .sort
      .map { |k, v| "#{k}=#{v}" }

    return "all" if sorted.empty?

    sorted.join("&")
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
