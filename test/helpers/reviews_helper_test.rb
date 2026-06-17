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
end
