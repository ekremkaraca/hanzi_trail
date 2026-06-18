require "test_helper"

module Flashcards
  class StoryQualityTagComponentTest < ViewComponent::TestCase
    test "renders needs expansion for short story" do
      flashcard = flashcards(:hsk_one)
      flashcard.story = "Too short."

      render_inline(StoryQualityTagComponent.new(flashcard: flashcard))

      assert_text "Needs expansion"
      assert_selector ".tag.is-danger"
    end

    test "does not render for normal story" do
      flashcard = flashcards(:network)
      flashcard.story = "x" * Flashcard::SHORT_STORY_LENGTH

      render_inline(StoryQualityTagComponent.new(flashcard: flashcard))

      assert_no_text "Needs expansion"
      assert_no_selector ".tag.is-danger"
    end
  end
end
