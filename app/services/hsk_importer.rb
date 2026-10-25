class HskImporter
  class ImportError < StandardError; end

  SOURCE = "hsk".freeze

  # Imported cards must not all be due at once: a fresh 4,240-word import
  # would otherwise dump an unworkable queue on the reviewer. Cards cycle
  # through STAGGER_CYCLE_DAYS days inside their level, and each level is
  # offset by one more cycle - level 1 fills the first month, level 2 the
  # next, and so on. The daily new-card cap in DueFlashcards is the second
  # line of defence on top of this spread.
  STAGGER_CYCLE_DAYS = 30

  # complete-hsk-vocabulary marks proper nouns with a capitalized pinyin and
  # lists the headword sense first: 书 arrives as "Shū" / "abbr. for 书经",
  # with the common sense "shū" / "book" in a later form. Importing the
  # first form therefore taught surnames and abbreviations — 12 cards came
  # in as "surname Shui" instead of "water" — so prefer the first form
  # whose pinyin is fully lowercase and keep the headword only when it is
  # the entry's sole form. The override exists for the one entry where
  # the first common-sense form is still the wrong sense: 那's first
  # lowercase form is "nǎ" ("variant of 哪"), but the common reading is
  # "nà".
  PREFERRED_READINGS = { "那" => "nà" }.freeze

  def self.import!(path:, level: nil, hsk_level: nil)
    new(path: path, hsk_level: hsk_level || level).import!
  end

  # The form whose reading should be imported: an explicit preference
  # first, then the first common-sense form (a fully lowercase pinyin),
  # then the headword.
  def self.form_for(entry)
    character = entry.fetch("simplified")
    forms = entry.fetch("forms")
    raise ImportError, "Entry '#{character}' has an empty forms array" if forms.empty?

    preferred = PREFERRED_READINGS[character]
    form = preferred && forms.find { |candidate| pinyin_of(candidate) == preferred }
    form ||= forms.find { |candidate| common_sense?(candidate) }
    form || forms.first
  end

  def self.pinyin_of(form)
    form.dig("transcriptions", "pinyin").to_s
  end

  def self.common_sense?(form)
    pinyin = pinyin_of(form)
    pinyin.present? && pinyin == pinyin.downcase
  end

  def initialize(path:, hsk_level:)
    @path = path
    @hsk_level = hsk_level
  end

  def call
    import!
  end

  def import!
    raise ImportError, "HSK file does not exist: #{path}" unless File.file?(path)

    data = parse_json
    raise ImportError, "HSK data must be an array" unless data.is_a?(Array)

    Flashcard.transaction do
      data.each_with_index { |entry, index| import_entry(entry, index: index) }
    end
  rescue KeyError => error
    raise ImportError, "Invalid HSK entry: missing #{error.key}"
  end

  private

  attr_reader :path, :hsk_level

  def import_entry(entry, index:)
    character = entry.fetch("simplified")

    flashcard = Flashcard.find_or_initialize_by(character: character)

    return if flashcard.persisted?

    form = self.class.form_for(entry)

    flashcard.assign_attributes(
      pinyin: form.fetch("transcriptions").fetch("pinyin"),
      meaning: form.fetch("meanings").join("; "),
      story: nil,
      story_status: "missing",
      source: SOURCE,
      hsk_level: hsk_level,
      next_review_at: staggered_due_date(index)
    )

    # Concurrent imports of the same character both miss the
    # find_or_initialize_by SELECT and race on INSERT. The
    # loser's unique violation must not poison the whole
    # import transaction, so save under a savepoint and
    # treat a lost race as "already imported".
    Flashcard.transaction(requires_new: true) { flashcard.save! }
    backfill_radical(entry)
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def staggered_due_date(index)
    Time.current +
      (index % STAGGER_CYCLE_DAYS).days +
      # Level 1 starts today (offset 0), level 2 one cycle later, etc.;
      # nil/malformed levels behave like level 1.
      ([ level_number - 1, 0 ].max * STAGGER_CYCLE_DAYS).days
  end

  # "new-3" -> 3, "old-1" -> 1, nil or malformed -> 0 (no level offset).
  def level_number
    hsk_level.to_s[/\A(?:new|old)-(\d+)\z/, 1].to_i
  end

  # The dataset's radical is the headword's Kangxi radical, so it can only
  # be attributed to a character when the entry IS that character; for
  # multi-character words it would mislabel nothing (skipped) rather than
  # guess. Runs after save so the relink callback has created the entry.
  # Curator-typed values are never overwritten.
  def backfill_radical(entry)
    character = entry.fetch("simplified")
    radical = entry["radical"]
    return unless character.length == 1 && radical.present?

    record = CharacterEntry.find_by(character: character)
    record.update!(radical: radical) if record&.radical.blank?
  end

  def parse_json
    JSON.parse(File.read(path))
  rescue JSON::ParserError => error
    raise ImportError, "Invalid JSON: #{error.message}"
  end
end
