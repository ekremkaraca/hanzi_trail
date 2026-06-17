module ReviewsHelper
  # DRY: all four rating buttons share the same outline primary look so the rating row reads as a unified control group.
  REVIEW_BUTTONS = {
    "again" => { label: "Again", key: "1" },
    "hard"  => { label: "Hard",  key: "2" },
    "good"  => { label: "Good",  key: "3" },
    "easy"  => { label: "Easy",  key: "4" }
  }.freeze

  REVIEW_MODES = [
    { mode: :all,             label: "All",             params: {} },
    { mode: :hsk,             label: "HSK",             params: { source: "hsk" } },
    { mode: :curated,         label: "Curated",         params: { source: "curated" } },
    { mode: :missing_stories, label: "Missing stories", params: { story_status: "missing" } }
  ].freeze

  def review_mode_active?(mode)
    case mode
    when :all then review_filter_params.values.all?(&:blank?)
    when :hsk then params[:source] == "hsk"
    when :curated then params[:source] == "curated"
    when :missing_stories then params[:story_status] == "missing"
    else
      false
    end
  end

  def review_mode_button_class(mode)
    # DRY: Pico styles `a[role=button]` natively; using a link with role=button (instead of button_to)
    # keeps the click target an anchor that Turbo navigates cleanly, and removes the
    # form/button wrapping that made the row visually noisy.
    class_names(
      "button",
      "is-small",
      "outline",
      "secondary": !review_mode_active?(mode),
      "primary": review_mode_active?(mode)
    )
  end

  def review_progress_text(reviewed_count, remaining_count)
    "#{reviewed_count} reviewed · #{remaining_count} remaining"
  end

  def review_button(flashcard, rating)
    config = REVIEW_BUTTONS.fetch(rating)

    button_to(
      "#{config.fetch(:label)} · #{config.fetch(:key)}",
      review_flashcard_path(flashcard),
      method: :patch,
      params: review_button_params(rating),
      class: "button outline primary",
      data: {
        review_rating: config.fetch(:key)
      }
    )
  end

  def review_buttons_for(flashcard)
    safe_join(
      REVIEW_BUTTONS.keys.map { |rating| review_button(flashcard, rating) }
    )
  end

  def review_progress_percentage(reviewed_count, total_count)
    return 0 if total_count.zero?

    ((reviewed_count.to_f / total_count) * 100).round
  end

  # DRY: render the mode-bar links from the REVIEW_MODES table.
  # Each mode is an anchor with role=button so Pico styles it like a button,
  # and Turbo navigates the GET request without any form ceremony.
  def review_mode_buttons
    safe_join(
      REVIEW_MODES.map do |config|
        link_to config.fetch(:label),
          review_path(config.fetch(:params)),
          role: "button",
          class: review_mode_button_class(config.fetch(:mode)),
          "aria-current": (review_mode_active?(config.fetch(:mode)) ? "page" : nil)
      end
    )
  end

  # DRY: shortcut hint text driven by REVIEW_BUTTONS keys
  def review_shortcut_keys
    REVIEW_BUTTONS.values.map { |config| config.fetch(:key) }.join(" · ")
  end

  # DRY: tab metadata for the review answer panel
  def review_answer_tabs(flashcard)
    tabs = [ [ 0, "Story", true ] ]
    tabs << [ 1, "Breakdown", has_breakdown?(flashcard) ] if has_breakdown?(flashcard)
    tabs << [ 2, "Context", has_context?(flashcard) ] if has_context?(flashcard)
    tabs
  end

  # DRY: tab panel component lookup — keeps the panel-class-to-index mapping in one place.
  REVIEW_TAB_COMPONENTS = {
    0 => ->(flashcard) { Reviews::TabPanels::StoryTabComponent.new(flashcard: flashcard) },
    1 => ->(flashcard) { Reviews::TabPanels::BreakdownTabComponent.new(flashcard: flashcard) },
    2 => ->(flashcard) { Reviews::TabPanels::ContextTabComponent.new(flashcard: flashcard) }
  }.freeze

  # DRY: render the tab list as <li> elements; safe_join ensures no stray nil entries.
  def review_answer_tab_list(flashcard)
    safe_join(
      review_answer_tabs(flashcard).map do |index, label, _visible|
        # Pico-native pattern: active state is signalled via aria-selected on the anchor, not via a Bulma class.
        tag.li(
          "data-index": index,
          "@click": "activeTab = #{index}"
        ) do
          tag.a(label,
            role: "tab",
            tabindex: 0,
            ":aria-selected": "activeTab === #{index}",
            "@click.prevent": "activeTab = #{index}")
        end
      end
    )
  end

  # DRY: render the tab panels (one per visible tab) as <div role="tabpanel"> wrappers,
  # each composing the corresponding TabPanels::* component.
  def review_answer_tab_panels(flashcard)
    safe_join(
      review_answer_tabs(flashcard).map do |index, _label, _visible|
        tag.div(
          class: "review-tab-panel",
          role: "tabpanel",
          "x-show": "activeTab === #{index}"
        ) do
          render(REVIEW_TAB_COMPONENTS.fetch(index).call(flashcard))
        end
      end
    )
  end

  def has_breakdown?(flashcard)
    flashcard.components.present? || flashcard.literal_meaning.present? || flashcard.mnemonic.present?
  end

  def has_context?(flashcard)
    flashcard.usage_note.present? || flashcard.character_entries.any?
  end

  private

  def review_filter_params
    # Delegates to the shared module so the helper and controller stay in
    # sync when a new filter key is added.
    Review::FilterParams.from(params)
  end

  def review_button_params(rating)
    {
      review: {
        rating: rating
      },
      # Use the shared module so blank values are dropped consistently with
      # the controller's redirect target and the session key.
      **Review::FilterParams.from(params)
    }
  end
end
