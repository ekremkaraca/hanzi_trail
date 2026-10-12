module StatsHelper
  REVIEW_RATINGS = Flashcard::REVIEW_RATINGS

  def rating_progress_class(rating)
    {
      "again" => "progress--danger",
      "hard" => "progress--warning",
      "good" => "progress--success",
      "easy" => "progress--info"
    }.fetch(rating)
  end
end
