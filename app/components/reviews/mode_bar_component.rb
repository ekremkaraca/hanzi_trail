module Reviews
  class ModeBarComponent < ViewComponent::Base
    # Mode metadata belongs with the component that renders the mode switcher.
    REVIEW_MODES = [
      { mode: :all,             label: "All",             params: {} },
      { mode: :hsk,             label: "HSK",             params: { source: "hsk" } },
      { mode: :curated,         label: "Curated",         params: { source: "curated" } },
      { mode: :missing_stories, label: "Missing stories", params: { story_status: "missing" } }
    ].freeze

    def initialize(filter_params:)
      @filter_params = filter_params
    end

    private

    attr_reader :filter_params

    def mode_links
      helpers.safe_join(
        REVIEW_MODES.map { |config| mode_link(config) }
      )
    end

    def mode_link(config)
      helpers.link_to config.fetch(:label),
        helpers.review_path(config.fetch(:params)),
        role: "button",
        class: mode_button_class(config.fetch(:mode)),
        "aria-current": (mode_active?(config.fetch(:mode)) ? "page" : nil)
    end

    def mode_button_class(mode)
      helpers.class_names(
        "button",
        "is-small",
        "outline",
        "secondary": !mode_active?(mode),
        "primary": mode_active?(mode)
      )
    end

    def mode_active?(mode)
      case mode
      when :all then filter_params.values.all?(&:blank?)
      when :hsk then filter_params[:source] == "hsk"
      when :curated then filter_params[:source] == "curated"
      when :missing_stories then filter_params[:story_status] == "missing"
      else false
      end
    end
  end
end
