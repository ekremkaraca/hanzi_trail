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
  # boundaries as the streak and the "reviewed today" counters. The zone
  # identifier is read from configuration, never hardcoded, so changing
  # config.time_zone keeps every day-scoped metric in step.
  # Aggregate distinct local days in SQL instead of loading every
  # reviewed_at into Ruby. The double AT TIME ZONE converts the stored UTC
  # timestamp to the app's configured zone before extracting the date.
  def dates
    @dates ||= ReviewAttempt
      .pluck(Arel.sql("DISTINCT (reviewed_at AT TIME ZONE 'UTC' AT TIME ZONE #{app_zone_sql})::date"))
  end

  def total_reviews
    @total_reviews ||= ReviewAttempt.count
  end

  # The zone identifier comes from the configured time zone (quoted for
  # SQL) so the velocity bucketing matches StreakCalculator and the
  # calendar-day counters.
  def app_zone_sql
    @app_zone_sql ||= ApplicationRecord.connection.quote(Time.zone.name)
  end
end
