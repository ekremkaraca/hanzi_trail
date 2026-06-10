class StreakCalculator
  def self.call
    new.call
  end

  def call
    # Normalize the SQL dates so the streak logic stays adapter-agnostic.
    dates = ReviewAttempt
      .where("reviewed_at >= ?", 1.year.ago)
      .distinct.pluck(Arel.sql("DATE(reviewed_at)"))
      .map(&:to_date)
      .sort
      .reverse

    streak = 0
    current = Date.current

    dates.each do |date|
      break unless date == current

      streak += 1
      current -= 1.day
    end

    streak
  end
end
