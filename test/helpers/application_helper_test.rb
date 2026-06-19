require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "active_review_link returns nil when session has no return path" do
    session[:review_return_to] = nil

    # Assert it returns nil or blank so nothing renders in ERB
    assert_nil link_to_active_review_if_present
  end

  test "active_review_link renders the correct button markup when session path is present" do
    target_path = "/reviews/all"
    session[:review_return_to] = target_path

    result = link_to_active_review_if_present

    # Verify it targets the correct URL from the session
    assert_match "href=\"#{target_path}\"", result
    # Verify our Bulma styling and layout texts are present
    assert_match "button is-info is-fullwidth", result
    assert_match "Return to Active Review", result
  end

  test "presence_or_dash returns value when present" do
    assert_equal "hello", presence_or_dash("hello")
  end

  test "presence_or_dash returns em-dash when value is blank" do
    assert_equal "—", presence_or_dash("")
    assert_equal "—", presence_or_dash(nil)
  end

  test "tag_if_present returns empty string when value is blank" do
    assert_equal "", tag_if_present("", color: "info")
    assert_equal "", tag_if_present(nil, color: "info")
  end

  test "tag_if_present renders a Bulma tag span when value is present" do
    result = tag_if_present("HSK 1", color: "info")

    assert_match "HSK 1", result
    assert_match "tag is-info", result
    assert_includes result, "span"
  end
end
