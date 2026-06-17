module ApplicationHelper
  def link_to_active_review_if_present
    return unless session[:review_return_to].present?

    link_to session[:review_return_to], class: "button is-info is-fullwidth mb-4" do
      concat content_tag(:span, "←", class: "icon mr-1")
      concat content_tag(:strong, "Return to Active Review")
    end
  end

  # DRY: shared "value or em-dash placeholder" used by flashcard detail rows
  def presence_or_dash(value)
    value.presence || "—"
  end

  # DRY: render a Bulma tag only when the value is present
  def tag_if_present(value, color:, css_class: "tag")
    return "" if value.blank?

    tag.span(value, class: "#{css_class} is-#{color}")
  end
end
