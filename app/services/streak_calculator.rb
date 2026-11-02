class StreakCalculator
  # Longest run of consecutive local days (ending today) with >=1 attempt.
  # Dedupe local days in SQL (DISTINCT) so the Ruby set holds one entry per
  # active day, not one row per attempt - otherwise this pluck grows with
  # the whole review_attempts table. Day bucketing uses Rails' configured
  # time zone instead of the DB's UTC DATE(reviewed_at), which used to roll
  # the streak over at 03:00 local.
  #
  # WINDOW_DAYS bounds the read: the pluck's row set grows one entry per
  # distinct active day forever, and a streak longer than the window is
  # unreachable from inside it - the walk stops at the first gap and days
  # past the window are never consulted. The window spans WINDOW_DAYS + 1
  # calendar days (from -366's local midnight through today), so runs
  # that short read exactly; longer ones cap at that count instead of
  # scanning all history. Bumping the constant moves the cap with it.
  WINDOW_DAYS = 366

  def self.call
    new.call
  end

  def call
    active = ReviewAttempt
             .where(reviewed_at: window_start..)
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

  # Local-midnight start of the window (Rails zone, matching the bucketing),
  # so the boundary day counts whole rather than being cut at a rolling hour.
  def window_start
    WINDOW_DAYS.days.ago.beginning_of_day
  end

  # The zone identifier is read from the configured time zone rather
  # than hardcoded, so the SQL day boundaries can never drift from the
  # Ruby-side boundaries (Date.current, Time.current.all_day) used by
  # the "reviewed today" counters and the stats page.
  def app_zone_sql
    @app_zone_sql ||= ApplicationRecord.connection.quote(Time.zone.name)
  end
end
