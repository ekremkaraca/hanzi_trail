class ReviewVelocity
  def self.call
    new.call
  end

  def call
    return 0 if dates.empty?

    (total_reviews.to_f / dates.size).round(1)
  end

  private

  # reviewed_at is stored as a UTC timestamp; bucket each attempt by its
  # local day (Rails-configured zone) so "active days" uses the same day
  # boundaries as the streak and the "reviewed today" counters.
  def dates
    @dates ||= ReviewAttempt
      .pluck(:reviewed_at)
      .map { |reviewed_at| reviewed_at.in_time_zone.to_date }
      .uniq
  end

  def total_reviews
    @total_reviews ||= ReviewAttempt.count
  end
end
