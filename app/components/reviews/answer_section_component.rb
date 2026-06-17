module Reviews
  class AnswerSectionComponent < ViewComponent::Base
    # Keep tab labels and panel components together so the section owns its UI map.
    TAB_DEFINITIONS = [
      {
        index: 0,
        label: "Story",
        visible: ->(_flashcard) { true },
        component: Reviews::TabPanels::StoryTabComponent
      },
      {
        index: 1,
        label: "Breakdown",
        visible: ->(flashcard) {
          flashcard.components.present? ||
            flashcard.literal_meaning.present? ||
            flashcard.mnemonic.present?
        },
        component: Reviews::TabPanels::BreakdownTabComponent
      },
      {
        index: 2,
        label: "Context",
        visible: ->(flashcard) {
          flashcard.usage_note.present? ||
            flashcard.character_entries.any?
        },
        component: Reviews::TabPanels::ContextTabComponent
      }
    ].freeze

    def initialize(flashcard:)
      @flashcard = flashcard
    end

    private

    attr_reader :flashcard

    def tabs
      TAB_DEFINITIONS.select { |tab| tab.fetch(:visible).call(flashcard) }
    end
  end
end
