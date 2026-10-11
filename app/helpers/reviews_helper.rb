module ReviewsHelper
  # Keep only scalar review formatting here; component-owned UI moved out.
  def review_progress_percentage(reviewed_count, total_count)
    return 0 if total_count.zero?

    ((reviewed_count.to_f / total_count) * 100).round
  end
end
