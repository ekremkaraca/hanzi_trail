class StreakCalculator
  # Longest run of consecutive local days (ending today) with >=1 attempt.
  # Walks backwards with one indexed EXISTS per day, so day bucketing uses
  # Rails' configured time zone via Date#all_day instead of the DB's UTC
  # DATE(reviewed_at) — which used to roll the streak over at 03:00 local.
  def self.call
    new.call
  end

  def call
    streak = 0
    day = Date.current

    while ReviewAttempt.where(reviewed_at: day.all_day).exists?
      streak += 1
      day -= 1
    end

    streak
  end
end
