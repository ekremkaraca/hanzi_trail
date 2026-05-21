class ReviewsController < ApplicationController
  def show
    queue = ReviewQueue.new(
      scope: Flashcard
        .by_source(params[:source])
        .by_category(params[:category])
        .by_story_status(params[:story_status])
    )

    @flashcard = queue.next_card
    @remaining_due_count = queue.remaining_count
    @empty_state_title = empty_state_title
  end

  def update
    flashcard = Flashcard.due_for_review.find(params[:flashcard_id])
    flashcard.schedule_next_review!(review_params[:rating])

    redirect_to review_path(review_params_for_redirect), notice: "Review saved."
  rescue ActiveRecord::RecordNotFound
    redirect_to review_path(review_params_for_redirect), alert: "This card is not due for review."
  rescue ArgumentError
    redirect_to review_path(review_params_for_redirect), alert: "Invalid review rating."
  end

  private

  def review_params
    params.require(:review).permit(:rating)
  end

  def review_params_for_redirect
    params.slice(:source, :category, :story_status).permit!
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
end
