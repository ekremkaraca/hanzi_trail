class ReviewsController < ApplicationController
  def show
    @flashcard = Flashcard.due_for_review.first
    @remaining_due_count = Flashcard.due_for_review.count
  end

  def update
    flashcard = Flashcard.due_for_review.find(params[:flashcard_id])
    flashcard.schedule_next_review!(review_params[:rating])

    redirect_to review_path, notice: "Review saved."
  rescue ActiveRecord::RecordNotFound
    redirect_to review_path, alert: "This card is not due for review."
  rescue ArgumentError
    redirect_to review_path, alert: "Invalid review rating."
  end

  private

  def review_params
    params.require(:review).permit(:rating)
  end
end
