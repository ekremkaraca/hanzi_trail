require "test_helper"

class ReviewsHelperTest < ActionView::TestCase
  test "review_progress_text formats reviewed and remaining counts" do
    assert_equal "3 reviewed · 9 remaining", review_progress_text(3, 9)
  end
end
