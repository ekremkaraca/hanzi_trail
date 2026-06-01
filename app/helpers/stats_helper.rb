module StatsHelper
  def rating_bar_width(rating, breakdown)
    total = breakdown.values.sum
    return "0%" if total.zero?

    "#{(breakdown[rating] || 0).to_f / total * 100}%"
  end

  def bar_fill_class(rating)
    "stats-bar-fill stats-bar--#{rating}"
  end

  def rating_badge_class(rating)
    "stats-list-rating stats-rating--#{rating}"
  end
end
