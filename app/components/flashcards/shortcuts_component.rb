module Flashcards
  class ShortcutsComponent < ViewComponent::Base
    STORY_STATUS_LINKS = {
      "missing" => { label: "Missing stories", css_class: "is-warning is-light" },
      "draft"   => { label: "Draft stories",   css_class: "is-info is-light" },
      "curated" => { label: "Curated stories", css_class: "is-success is-light" },
      "short"   => { label: "Short stories",   css_class: "is-light" }
    }.freeze

    def initialize(status: nil)
      @status = status
    end

    private

    attr_reader :status

    def statuses
      @statuses ||= @status ? [ @status ] : STORY_STATUS_LINKS.keys
    end

    def shortcut_links
      safe_join(
        statuses.map { |s| render(Flashcards::ShortcutLinkComponent.new(status: s)) }
      )
    end
  end
end
