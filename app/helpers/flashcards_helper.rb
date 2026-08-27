module FlashcardsHelper
  STORY_STATUSES = {
    "missing" => [ "Missing Story", "is-warning" ],
    "draft"   => [ "Draft Story",   "is-info" ],
    "curated" => [ "Curated Story", "is-success" ]
  }.freeze
  DEFAULT_STORY_STATUS = [ "Unknown Story", "is-light" ].freeze

  STORY_QUALITY_LABELS = {
    short: [ "Needs expansion", "is-danger" ]
  }.freeze

  EMPTY_TITLE_MAP = {
    "draft"   => "No draft stories found.",
    "curated" => "No curated stories found.",
    "missing" => "No missing stories found.",
    "short"   => "No short stories found."
  }.freeze

  def story_status_tag(flashcard)
    label, css_class = STORY_STATUSES.fetch(flashcard.story_status, DEFAULT_STORY_STATUS)

    tag.span(label, class: "tag #{css_class}")
  end

  def story_quality_tag(flashcard)
    return nil unless flashcard.short_story?

    label, css_class = STORY_QUALITY_LABELS[:short]

    tag.span(label, class: "tag #{css_class}")
  end

  def flashcards_empty_title
    story_status = params[:story_status]

    EMPTY_TITLE_MAP.fetch(story_status, "No flashcards matched your filter.")
  end

  def flashcard_character_size_class(flashcard)
    length = flashcard.character.to_s.length

    if length >= 4
      "is-phrase-character"
    elsif length == 3
      "is-long-character"
    else
      ""
    end
  end
end
