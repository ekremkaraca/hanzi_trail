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

  test "story_status_tag renders unknown story tag for unexpected status" do
    flashcard = flashcards(:network)
    flashcard.story_status = "unexpected"

    html = story_status_tag(flashcard)

    assert_includes html, "Unknown Story"
    assert_includes html, "is-light"
  end

  test "flashcards_empty_title for draft story status" do
    params[:story_status] = "draft"

    assert_equal "No draft stories found.", flashcards_empty_title
  end

  test "flashcards_empty_title for curated story status" do
    params[:story_status] = "curated"

    assert_equal "No curated stories found.", flashcards_empty_title
  end

  test "flashcards_empty_title for missing story status" do
    params[:story_status] = "missing"

    assert_equal "No missing stories found.", flashcards_empty_title
  end

  test "flashcards_empty_title for short story filter" do
    params[:story_status] = "short"

    assert_equal "No short stories found.", flashcards_empty_title
  end

  test "flashcards_empty_title default message" do
    assert_equal "No flashcards matched your filter.", flashcards_empty_title
  end

  test "flashcard_character_size_class returns is-phrase-character for 4+ chars" do
    flashcard = flashcards(:network)
    flashcard.character = "四个汉字"

    assert_equal "is-phrase-character", flashcard_character_size_class(flashcard)
  end

  test "flashcard_character_size_class returns is-long-character for 3 chars" do
    flashcard = flashcards(:network)
    flashcard.character = "三个字"

    assert_equal "is-long-character", flashcard_character_size_class(flashcard)
  end

  test "flashcard_character_size_class returns blank for 1-2 chars" do
    flashcard = flashcards(:network)

    assert_equal "", flashcard_character_size_class(flashcard)
  end
end
