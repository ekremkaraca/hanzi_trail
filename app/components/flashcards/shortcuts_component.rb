module Flashcards
  class ShortcutsComponent < ViewComponent::Base
    STORY_STATUS_LINKS = {
      "missing" => { label: "Missing stories", tone: "btn--soft-warning" },
      "draft"   => { label: "Draft stories",   tone: "btn--soft-info" },
      "curated" => { label: "Curated stories", tone: "btn--soft-success" },
      "short"   => { label: "Short stories",   tone: "btn--ghost" }
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
