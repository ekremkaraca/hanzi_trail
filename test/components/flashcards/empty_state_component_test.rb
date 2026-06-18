require "test_helper"

module Flashcards
  class EmptyStateComponentTest < ViewComponent::TestCase
    include Rails.application.routes.url_helpers

    test "renders story-status-specific titles" do
      {
        "draft" => "No draft stories found.",
        "curated" => "No curated stories found.",
        "missing" => "No missing stories found.",
        "short" => "No short stories found."
      }.each do |story_status, title|
        render_inline(EmptyStateComponent.new(story_status: story_status))

        assert_text title
      end
    end

    test "renders default title and actions" do
      render_inline(EmptyStateComponent.new)

      assert_text "No flashcards matched your filter."
      assert_selector "a[href='#{flashcards_path(story_status: "missing")}']", text: "Missing stories"
      assert_selector "a[href='#{flashcards_path}']", text: "Browse all flashcards"
    end
  end
end
