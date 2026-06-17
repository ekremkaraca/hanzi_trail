module Flashcards
  class ShortcutLinkComponent < ViewComponent::Base
    def initialize(status:)
      @status = status
    end

    private

    attr_reader :status

    def config
      ShortcutsComponent::STORY_STATUS_LINKS.fetch(status)
    end

    def label
      config.fetch(:label)
    end

    def css_class
      "button #{config.fetch(:css_class)}"
    end
  end
end
