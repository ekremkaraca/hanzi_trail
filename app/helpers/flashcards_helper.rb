module FlashcardsHelper
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

    tag.span(label, class: "tag #{css_class} is-light")
  end

  def story_quality_tag(flashcard)
    return unless flashcard.short_story?

    tag.span("Needs expansion", class: "tag is-danger is-light")
  end

  def flashcards_empty_title
    return "No draft stories found." if params[:story_status] == "draft"
    return "No curated stories found." if params[:story_status] == "curated"
    return "No missing stories found." if params[:story_status] == "missing"
    return "No short stories found." if params[:story_status] == "1"

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
end
