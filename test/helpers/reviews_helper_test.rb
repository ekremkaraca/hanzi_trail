require "test_helper"

class ReviewsHelperTest < ActionView::TestCase
  test "review_progress_text formats reviewed and remaining counts" do
    assert_equal "3 reviewed · 9 remaining", review_progress_text(3, 9)
  end

  test "review_progress_percentage returns zero when total is zero" do
    assert_equal 0, review_progress_percentage(0, 0)
  end

  test "review_progress_percentage calculates rounded percentage" do
    assert_equal 25, review_progress_percentage(1, 4)
    assert_equal 50, review_progress_percentage(2, 4)
    assert_equal 100, review_progress_percentage(4, 4)
  end

  test "review_mode_active? returns true when all filters blank" do
    assert review_mode_active?(:all)
  end

  test "review_mode_active? returns false when source filter active" do
    params[:source] = "hsk"

    assert_not review_mode_active?(:all)
  end

  test "review_mode_active? detects hsk mode" do
    params[:source] = "hsk"

    assert review_mode_active?(:hsk)
  end

  test "review_mode_active? detects curated mode" do
    params[:source] = "curated"

    assert review_mode_active?(:curated)
  end

  test "review_mode_active? detects missing stories mode" do
    params[:story_status] = "missing"

    assert review_mode_active?(:missing_stories)
  end

  test "review_mode_active? returns false for unknown mode" do
    assert_not review_mode_active?(:unknown)
  end

  test "review_mode_button_class marks the active mode with primary variant" do
    assert_includes review_mode_button_class(:all), "primary"
  end

  test "review_mode_button_class marks inactive modes with secondary variant" do
    params[:source] = "hsk"

    assert_includes review_mode_button_class(:all), "secondary"
    assert_includes review_mode_button_class(:hsk), "primary"
  end

  test "review_button renders form for correct rating" do
    flashcard = flashcards(:network)

    html = review_button(flashcard, "good")

    assert_includes html, "Good · 3"
    assert_includes html, 'class="button outline primary"'
    assert_includes html, 'value="good"'
    assert_includes html, 'name="review[rating]"'
  end

  test "review_buttons_for renders all four rating buttons" do
    flashcard = flashcards(:network)

    html = review_buttons_for(flashcard)

    assert_includes html, "Again · 1"
    assert_includes html, "Hard · 2"
    assert_includes html, "Good · 3"
    assert_includes html, "Easy · 4"
  end
end
