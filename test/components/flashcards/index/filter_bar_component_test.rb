require "test_helper"

module Flashcards
  module Index
    class FilterBarComponentTest < ViewComponent::TestCase
      test "selects are wired to auto-submit, text fields are not" do
        render_inline(FilterBarComponent.new(params: {}))

        assert_selector "form[data-controller='auto-submit']"

        %w[source hsk_level story_status].each do |field|
          assert_selector "select[name='#{field}'][data-action='auto-submit#submit']"
        end

        # Typing in query/category must not fire a request per keystroke.
        assert_selector "input[name='query']", count: 1
        assert_no_selector "input[name='query'][data-action]"
        assert_no_selector "input[name='category'][data-action]"

        # Manual submit still available.
        assert_selector "input[type=submit][value='Filter']"
      end

      test "hsk options are derived from the data with learner-facing labels" do
        # Fixtures carry old-1 only -> exactly one level option besides All.
        render_inline(FilterBarComponent.new(params: {}))

        assert_selector "select[name='hsk_level'] option[value='']"
        assert_selector "select[name='hsk_level'] option[value='old-1']",
          text: "HSK 2.0 (1)"
        assert_selector "select[name='hsk_level'] option", count: 2
      end
    end
  end
end
