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
    case
    when params[:source] == "hsk"
      "No HSK cards are due right now."
    when params[:source] == "curated"
      "No curated cards are due right now."
    when params[:category] == "technical"
      "No technical cards are due right now."
    else
      "No cards due right now."
    end
  end
end
