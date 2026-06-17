require "test_helper"

module Reviews
  class ModeBarComponentTest < ViewComponent::TestCase
    test "marks all mode active when filters are blank" do
      render_inline(ModeBarComponent.new(filter_params: {}))

      assert_selector "a[aria-current='page']", text: "All"
      assert_selector "a.primary", text: "All"
    end

    test "marks source mode active from explicit filters" do
      render_inline(ModeBarComponent.new(filter_params: { source: "hsk" }))

      assert_selector "a[aria-current='page']", text: "HSK"
      assert_selector "a.primary", text: "HSK"
      assert_selector "a.secondary", text: "All"
    end

    test "marks story status mode active from explicit filters" do
      render_inline(ModeBarComponent.new(filter_params: { story_status: "missing" }))

      assert_selector "a[aria-current='page']", text: "Missing stories"
      assert_selector "a.primary", text: "Missing stories"
    end
  end
end
