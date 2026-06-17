module Shared
  class CollapsibleBoxComponent < ViewComponent::Base
    def initialize(id:, title:, eyebrow: nil, open: false, badge: nil)
      @id = id
      @title = title
      @eyebrow = eyebrow
      @open = open
      @badge = badge
    end

    private

    attr_reader :id, :title, :eyebrow, :open, :badge

    def show_eyebrow?
      eyebrow.present?
    end

    def show_badge?
      badge.present?
    end

    def aria_expanded
      open.to_s
    end
  end
end
