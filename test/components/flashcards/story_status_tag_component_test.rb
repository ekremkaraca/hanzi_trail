require "test_helper"

module Flashcards
  class StoryStatusTagComponentTest < ViewComponent::TestCase
    test "renders missing story tag" do
      flashcard = flashcards(:hsk_one)
      flashcard.story_status = "missing"

      render_inline(StoryStatusTagComponent.new(flashcard: flashcard))

      assert_text "Missing Story"
      assert_selector ".tag.is-warning"
    end

    test "renders draft story tag" do
      flashcard = flashcards(:network)
      flashcard.story_status = "draft"

      render_inline(StoryStatusTagComponent.new(flashcard: flashcard))

      assert_text "Draft Story"
      assert_selector ".tag.is-info"
    end

    test "renders curated story tag" do
      flashcard = flashcards(:network)
      flashcard.story_status = "curated"

      render_inline(StoryStatusTagComponent.new(flashcard: flashcard))

      assert_text "Curated Story"
      assert_selector ".tag.is-success"
    end

    test "renders unknown story tag for unexpected status" do
      flashcard = flashcards(:network)
      flashcard.story_status = "unexpected"

      render_inline(StoryStatusTagComponent.new(flashcard: flashcard))

      assert_text "Unknown Story"
      assert_selector ".tag.is-light"
    end
  end
end
