class StreakCalculator
  def self.call
    new.call
  end

  def call
    # Normalize the SQL dates so the streak logic stays Postgres-specific.
    dates = ReviewAttempt
      .select("DATE(reviewed_at) AS d")
      .distinct
      .order(Arel.sql("DATE(reviewed_at) DESC"))
      .map(&:d)

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
