module FlashcardsHelper
  STORY_STATUS_LINKS = {
    "missing" => { label: "Missing stories", class: "is-warning is-light" },
    "draft"   => { label: "Draft stories",   class: "is-info is-light" },
    "curated" => { label: "Curated stories", class: "is-success is-light" },
    "short"   => { label: "Short stories",   class: "is-light" }
  }.freeze

  def story_status_tag(flashcard)
    label, css_class =
      case flashcard.story_status
      when "missing"
        [ "Missing Story", "is-warning" ]
      when "draft"
        [ "Draft Story", "is-info" ]
      when "curated"
        [ "Curated Story", "is-success" ]
      else
        [ "Unknown Story", "is-light" ]
      end

    tag.span(label, class: "tag #{css_class}")
  end

  def story_quality_tag(flashcard)
    return unless flashcard.short_story?

    tag.span("Needs expansion", class: "tag is-danger")
  end

  def flashcards_empty_title
    return "No draft stories found." if params[:story_status] == "draft"
    return "No curated stories found." if params[:story_status] == "curated"
    return "No missing stories found." if params[:story_status] == "missing"
    return "No short stories found." if params[:story_status] == "short"

    "No flashcards matched your filter."
  end

  def flashcard_character_size_class(flashcard)
    length = flashcard.character.length

    if length >= 4
      "is-phrase-character"
    elsif length >= 3
      "is-long-character"
    else
      ""
    end
  end

  # DRY: shared "Overdue by X" / "Due in Y" formatting for the show page
  def next_review_text(flashcard)
    time = flashcard.next_review_at

    if time.past?
      "Overdue by #{distance_of_time_in_words(time, Time.current)}"
    else
      "Due in #{distance_of_time_in_words(Time.current, time)}"
    end
  end

  # DRY: shared "X ago" / "Never" formatting for the show page
  def last_reviewed_text(flashcard)
    return "Never" if flashcard.last_reviewed_at.blank?

    "#{time_ago_in_words(flashcard.last_reviewed_at)} ago"
  end

  # DRY: data-driven curation shortcut links (see STORY_STATUS_LINKS)
  def story_status_shortcut_link(status)
    config = STORY_STATUS_LINKS.fetch(status)

    link_to config.fetch(:label), flashcards_path(story_status: status), class: "button #{config.fetch(:class)}"
  end

  def story_status_shortcut_links
    safe_join(
      STORY_STATUS_LINKS.keys.map { |status| story_status_shortcut_link(status) }
    )
  end
end
