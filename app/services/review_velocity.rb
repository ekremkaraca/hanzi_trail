class ReviewVelocity
  def self.call
    new.call
  end

  def call
    return 0 if active_days.zero?

    (total_reviews.to_f / active_days).round(1)
  end

  private

  def total_reviews
    @total_reviews ||= ReviewAttempt.count
  end

  def active_days
    @active_days ||=
      ReviewAttempt
        .distinct
        .pluck(Arel.sql("DATE(reviewed_at)"))
        .count
  end
end
