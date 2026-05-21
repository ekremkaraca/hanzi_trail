module ReviewsHelper
  def review_mode_active?(mode)
    case mode
    when :all then review_filter_params.values.all?(&:blank?)
    when :hsk then params[:source] == "hsk"
    when :curated then params[:source] == "curated"
    when :missing_stories then params[:story_status] == "missing"
    else
      false
    end
  end

  def review_mode_button_class(mode)
    class_names(
      "button",
      "is-small",
      "is-active": review_mode_active?(mode)
    )
  end

  private

  def review_filter_params
    params.slice(:source, :category, :story_status)
  end
end
