require "test_helper"

module Reviews
  class ModeBarComponentTest < ViewComponent::TestCase
    include Rails.application.routes.url_helpers

    test "renders all mode links" do
      render_inline(ModeBarComponent.new(filter_params: {}))

      assert_text "All"
      assert_text "HSK"
      assert_text "Curated"
      assert_text "Missing stories"
    end

    test "marks all as active when no filters are set" do
      render_inline(ModeBarComponent.new(filter_params: {}))

      assert_selector "a[aria-current='page']", text: "All"
    end

    test "marks HSK as active when source is hsk" do
      render_inline(ModeBarComponent.new(filter_params: { source: "hsk" }))

      assert_selector "a[aria-current='page']", text: "HSK"
    end

    test "marks curated as active when source is curated" do
      render_inline(ModeBarComponent.new(filter_params: { source: "curated" }))

      assert_selector "a[aria-current='page']", text: "Curated"
    end

    test "marks missing stories as active when story_status is missing" do
      render_inline(ModeBarComponent.new(filter_params: { story_status: "missing" }))

      assert_selector "a[aria-current='page']", text: "Missing stories"
    end
  end
end
