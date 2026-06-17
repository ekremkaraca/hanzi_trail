module Flashcards
  class TagIfPresentComponent < ViewComponent::Base
    def initialize(value, color:, css_class: "tag")
      @value = value
      @color = color
      @css_class = css_class
    end

    def render?
      @value.present?
    end

    private

    attr_reader :value, :color, :css_class

    def full_class
      "#{css_class} is-#{color}"
    end
  end
end
