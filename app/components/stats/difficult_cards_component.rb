module Stats
  class DifficultCardsComponent < ViewComponent::Base
    def initialize(difficult_cards:)
      @difficult_cards = difficult_cards
    end

    private

    attr_reader :difficult_cards

    def badge
      helpers.content_tag(:span, "Top 10", class: "tag is-warning")
    end

    def flashcard_path(card)
      helpers.flashcard_path(card)
    end

    def any_cards?
      difficult_cards.any?
    end
  end
end
