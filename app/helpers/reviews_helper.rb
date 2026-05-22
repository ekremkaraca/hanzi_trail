module ReviewsHelper
  REVIEW_BUTTONS = {
    "again" => {
      label: "Again",
      key: "1",
      class: "is-danger"
    },
    "hard" => {
      label: "Hard",
      key: "2",
      class: "is-warning"
    },
    "good" => {
      label: "Good",
      key: "3",
      class: "is-success"
    },
    "easy" => {
      label: "Easy",
      key: "4",
      class: "is-info"
    }
  }.freeze

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

  def review_progress_text(reviewed_count, remaining_count)
    "#{reviewed_count} reviewed · #{remaining_count} remaining"
  end

  def review_button(flashcard, rating)
    config = REVIEW_BUTTONS.fetch(rating)

    button_to(
      "#{config[:label]} [#{config[:key]}]",
      review_flashcard_path(flashcard),
      method: :patch,
      params: review_button_params(rating),
      class: "button #{config[:class]} is-medium",
      data: {
        review_rating: config[:key]
      }
    )
  end

  private

  def review_filter_params
    params.slice(:source, :category, :story_status)
  end

  def review_button_params(rating)
    {
      review: {
        rating: rating
      },
      source: params[:source],
      category: params[:category],
      story_status: params[:story_status]
    }
  end
end
