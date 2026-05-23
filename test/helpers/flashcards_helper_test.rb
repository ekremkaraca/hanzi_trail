require "test_helper"

class FlashcardsHelperTest < ActionView::TestCase
  test "story_status_tag renders missing story tag" do
    flashcard = flashcards(:hsk_one)
    flashcard.story_status = "missing"

    html = story_status_tag(flashcard)

    assert_includes html, "Missing Story"
    assert_includes html, "is-warning"
  end

  test "story_status_tag renders draft story tag" do
    flashcard = flashcards(:network)
    flashcard.story_status = "draft"

    html = story_status_tag(flashcard)

    assert_includes html, "Draft Story"
    assert_includes html, "is-info"
  end

  test "story_status_tag renders curated story tag" do
    flashcard = flashcards(:network)
    flashcard.story_status = "curated"

    html = story_status_tag(flashcard)

    assert_includes html, "Curated Story"
    assert_includes html, "is-success"
  end

  test "story_quality_tag renders needs expansion for short story" do
    flashcard = flashcards(:hsk_one)
    flashcard.story = "Too short."

    html = story_quality_tag(flashcard)

    assert_includes html, "Needs expansion"
    assert_includes html, "is-danger"
  end

  test "story_quality_tag returns nil for normal story" do
    flashcard = flashcards(:network)
    flashcard.story = "This is one of the proper story with enough detail to be useful during review process."

    assert_nil story_quality_tag(flashcard)
  end
end
