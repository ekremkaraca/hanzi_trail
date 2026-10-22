class StreakCalculator
  # Longest run of consecutive local days (ending today) with >=1 attempt.
  # Dedupe local days in SQL (DISTINCT) so the Ruby set holds one entry per
  # active day, not one row per attempt — otherwise this pluck grows with
  # the whole review_attempts table. Day bucketing uses Rails' configured
  # time zone instead of the DB's UTC DATE(reviewed_at), which used to roll
  # the streak over at 03:00 local.
  def self.call
    new.call
  end

  def call
    active = ReviewAttempt
      .pluck(Arel.sql("DISTINCT (reviewed_at AT TIME ZONE 'UTC' AT TIME ZONE #{app_zone_sql})::date"))
      .to_set

    streak = 0
    day = Date.current
    while active.include?(day)
      streak += 1
      day -= 1
    end

    streak
  end

  private

  # The zone identifier is read from the configured time zone rather
  # than hardcoded, so the SQL day boundaries can never drift from the
  # Ruby-side boundaries (Date.current, Time.current.all_day) used by
  # the "reviewed today" counters and the stats page.
  def app_zone_sql
    @app_zone_sql ||= ApplicationRecord.connection.quote(Time.zone.name)
  end
end
