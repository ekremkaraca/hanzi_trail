class HskImporter
  class ImportError < StandardError; end

  SOURCE = "hsk".freeze

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
      data.each { |entry| import_entry(entry) }
    end
  rescue KeyError => error
    raise ImportError, "Invalid HSK entry: missing #{error.key}"
  end

  private

  attr_reader :path, :hsk_level

  def import_entry(entry)
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
      next_review_at: Time.current
    )

    # Concurrent imports of the same character both miss the
    # find_or_initialize_by SELECT and race on INSERT. The
    # loser's unique violation must not poison the whole
    # import transaction, so save under a savepoint and
    # treat a lost race as "already imported".
    Flashcard.transaction(requires_new: true) { flashcard.save! }
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def parse_json
    JSON.parse(File.read(path))
  rescue JSON::ParserError => error
    raise ImportError, "Invalid JSON: #{error.message}"
  end
end
