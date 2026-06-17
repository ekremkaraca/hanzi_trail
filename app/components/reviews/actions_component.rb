module Reviews
  class ActionsComponent < ViewComponent::Base
    # Own rating metadata here so the component fully defines the action row.
    REVIEW_BUTTONS = {
      "again" => { label: "Again", key: "1" },
      "hard"  => { label: "Hard",  key: "2" },
      "good"  => { label: "Good",  key: "3" },
      "easy"  => { label: "Easy",  key: "4" }
    }.freeze

    def initialize(flashcard:, filter_params:)
      @flashcard = flashcard
      @filter_params = filter_params
    end

    private

    attr_reader :flashcard, :filter_params

    def rating_buttons
      helpers.safe_join(
        REVIEW_BUTTONS.keys.map { |rating| review_button(rating) }
      )
    end

    def shortcut_keys
      REVIEW_BUTTONS.values.map { |config| config.fetch(:key) }.join(" · ")
    end

    def review_button(rating)
      config = REVIEW_BUTTONS.fetch(rating)

      helpers.button_to(
        "#{config.fetch(:label)} · #{config.fetch(:key)}",
        helpers.review_flashcard_path(flashcard),
        method: :patch,
        params: review_button_params(rating),
        class: "button outline primary",
        data: { review_rating: config.fetch(:key) }
      )
    end

    def review_button_params(rating)
      # Use explicit page filter state instead of reaching back into helper params.
      {
        review: { rating: rating },
        **filter_params
      }
    end
  end
end
