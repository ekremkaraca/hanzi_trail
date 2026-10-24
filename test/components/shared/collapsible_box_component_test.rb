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

    test "starts closed with the Stimulus wiring" do
      render_inline(CollapsibleBoxComponent.new(id: "test", title: "Details")) { "content" }

      assert_selector "article[data-controller='collapsible']"
      assert_selector "button.collapsible-header[data-action~='click->collapsible#toggle'][aria-expanded='false']"
      assert_selector "#test-content.collapsible-body[data-collapsible-target='body'][hidden]", visible: false
      assert_selector ".collapsible-caret[data-collapsible-target='caret']"
      assert_no_selector ".collapsible-caret--open"
    end

    test "starts open when asked" do
      render_inline(CollapsibleBoxComponent.new(id: "test", title: "Details", open: true)) { "content" }

      assert_selector "button.collapsible-header[aria-expanded='true']"
      assert_selector "#test-content.collapsible-body[data-collapsible-target='body']"
      assert_no_selector "#test-content[hidden]"
      assert_selector ".collapsible-caret--open[data-collapsible-target='caret']"
    end
  end
end
