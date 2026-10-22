require "test_helper"

module Reviews
  class PreferencesComponentTest < ViewComponent::TestCase
    test "keeps the show-pinyin control reachable on every viewport" do
      render_inline(PreferencesComponent.new(show_pinyin: false, filter_params: {}))

      # The wrapper used to carry hidden-mobile, which made the only control
      # for this preference display:none below 768px.
      assert_selector "form input[type=checkbox][name=show_pinyin]"
      assert_no_selector ".hidden-mobile"
    end

    test "posts to the named preferences route instead of a literal path" do
      render_inline(PreferencesComponent.new(show_pinyin: false, filter_params: {}))

      action = Rails.application.routes.url_helpers.review_preferences_path
      assert_selector "form[method=post][action='#{action}']"
    end

    test "reflects the saved preference and carries the active filters" do
      render_inline(PreferencesComponent.new(
        show_pinyin: true,
        filter_params: { source: "hsk", category: nil, story_status: "missing" }
      ))

      # Hidden inputs are invisible to Capybara's default filter, so the
      # assertions below opt out of it explicitly.
      assert_selector "input[type=checkbox][name=show_pinyin][checked=checked]"
      assert_selector "input[type=hidden][name=source][value=hsk]", visible: :all
      assert_selector "input[type=hidden][name=story_status][value=missing]", visible: :all
      # An inactive filter renders no value at all, so the empty hidden field
      # cannot shadow a real filter in the controller's FilterParams read.
      assert_selector "input[type=hidden][name=category]:not([value])", visible: :all
    end
  end
end
