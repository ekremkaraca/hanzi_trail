require "test_helper"

module Reviews
  class ActionsComponentTest < ViewComponent::TestCase
    include Rails.application.routes.url_helpers

    test "renders rating buttons with filter params" do
      flashcard = flashcards(:network)

      render_inline(
        ActionsComponent.new(
          flashcard: flashcard,
          filter_params: { source: "hsk", story_status: "missing" }
        )
      )

      assert_text "Again · 1"
      assert_text "Hard · 2"
      assert_text "Good · 3"
      assert_text "Easy · 4"
      assert_selector "form[action='#{review_flashcard_path(flashcard)}'][method='post']"
      assert_selector "input[name='review[rating]'][value='good']", visible: false
      assert_selector "input[name='source'][value='hsk']", visible: false
      assert_selector "input[name='story_status'][value='missing']", visible: false
    end

    test "renders shortcut key hint from component metadata" do
      render_inline(
        ActionsComponent.new(
          flashcard: flashcards(:network),
          filter_params: {}
        )
      )

      assert_text "Use 1 · 2 · 3 · 4 keys for quick review"
    end
  end
end
