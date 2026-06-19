require "test_helper"

module Shared
  class CollapsibleBoxComponentTest < ViewComponent::TestCase
    test "renders title" do
      render_inline(CollapsibleBoxComponent.new(id: "test", title: "Details")) { "content" }

      assert_text "Details"
      assert_text "content"
    end

    test "shows eyebrow when provided" do
      render_inline(
        CollapsibleBoxComponent.new(id: "test", title: "Details", eyebrow: "Section")
      ) { "content" }

      assert_text "Section"
    end

    test "shows badge when provided" do
      render_inline(
        CollapsibleBoxComponent.new(id: "test", title: "Details", badge: "3")
      ) { "content" }

      assert_text "3"
    end

    test "renders x-data with open state" do
      render_inline(CollapsibleBoxComponent.new(id: "test", title: "Details", open: true)) { "content" }

      assert_selector "article[x-data*='open: true']"
    end
  end
end
