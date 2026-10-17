module Shared
  class FlashComponent < ViewComponent::Base
    def render?
      messages.any?
    end

    private

    def messages
      @messages ||= helpers.flash.to_hash
    end

    def icon_for(type)
      type.to_s == "notice" ? "✓" : "!"
    end

    def flash_message_class(type)
      "flash-message flash-message--#{type}"
    end
  end
end
