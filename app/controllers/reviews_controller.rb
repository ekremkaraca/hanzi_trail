class ReviewsController < ApplicationController
  def show
    @flashcard = Flashcard.due_for_review.first
  end

  def update
    flashcard = Flashcard.find(params[:flashcard_id])
    flashcard.schedule_next_review!(review_params.fetch(:rating))

    redirect_to review_path, notice: "Review saved."
  rescue ArgumentError
    redirect_to review_path, alert: "Invalid review rating."
  end

  private

  def review_params
    params.require(:review).permit(:rating)
  end
end
