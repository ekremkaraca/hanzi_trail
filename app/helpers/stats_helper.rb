module StatsHelper
  REVIEW_RATINGS = %w[again hard good easy].freeze

  def rating_progress_class(rating)
    {
      "again" => "is-danger",
      "hard" => "is-warning",
      "good" => "is-success",
      "easy" => "is-info"
    }.fetch(rating)
  end
end
