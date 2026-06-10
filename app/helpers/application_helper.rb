module ApplicationHelper
  def link_to_active_review_if_present
    return unless session[:review_return_to].present?

    link_to session[:review_return_to], class: "button is-info is-fullwidth mb-4" do
      concat content_tag(:span, "←", class: "icon mr-1")
      concat content_tag(:strong, "Return to Active Review")
    end
  end
end
