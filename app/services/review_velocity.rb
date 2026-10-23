class ReviewVelocity
  # Average reviews per active day. Counted inside the same
  # StreakCalculator::WINDOW_DAYS horizon the streak uses - one constant
  # for both day-based metrics. Both sides of the ratio must share the
  # window: bounding only the distinct days while counting all history
  # would deflate the average as the table grows.
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
  # timestamp to the app's configured zone before extracting the date, and
  # the window keeps the result set from growing with the table.
  def dates
    @dates ||= window
      .pluck(Arel.sql("DISTINCT (reviewed_at AT TIME ZONE 'UTC' AT TIME ZONE #{app_zone_sql})::date"))
  end

  def total_reviews
    @total_reviews ||= window.count
  end

  # Local-midnight window start (Rails zone, matching the bucketing),
  # shared by both sides of the ratio.
  def window
    @window ||= ReviewAttempt.where(
      reviewed_at: StreakCalculator::WINDOW_DAYS.days.ago.beginning_of_day..
    )
  end

  # The zone identifier comes from the configured time zone (quoted for
  # SQL) so the velocity bucketing matches StreakCalculator and the
  # calendar-day counters.
  def app_zone_sql
    @app_zone_sql ||= ApplicationRecord.connection.quote(Time.zone.name)
  end
end
