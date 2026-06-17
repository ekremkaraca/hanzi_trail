module Reviews
  class CharacterLabelComponent < ViewComponent::Base
    def initialize(flashcard:, attribute:, label:, color:, full_width: false)
      @flashcard = flashcard
      @attribute = attribute
      @label = label
      @color = color
      @full_width = full_width
    end

    def render?
      @flashcard.public_send(@attribute).present?
    end

    private

    attr_reader :flashcard, :attribute, :label, :color, :full_width

    def wrapper_classes
      [ "mb-2", ("span-full" if full_width) ].compact.join(" ")
    end

    def color_class
      "text-#{color}"
    end
  end
end
