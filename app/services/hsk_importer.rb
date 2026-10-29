class HskImporter
  class ImportError < StandardError; end

  SOURCE = "hsk".freeze

  # Imported cards are due immediately: the due-date pacing that the old
  # import-time stagger provided is now entirely the daily new-card cap in
  # DueFlashcards (20/day, uncapped inside an explicit hsk_level filter).
  # The stagger kept cards locked out of review for months — fatal for a
  # companion app whose whole point is drilling HSK3 words on demand —
  # while duplicating what the cap already does.

  # Entries per committed chunk. One transaction per level meant a killed
  # ssh session on Fly (scale-to-zero mid-import) rolled back everything
  # done so far; committed chunks make the import resumable - a re-run
  # skips persisted characters and continues where it stopped.
  CHUNK_SIZE = 100

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

    indexed = data.each_with_index.to_a
    imported = 0
    processed = 0

    indexed.each_slice(CHUNK_SIZE) do |slice|
      Flashcard.transaction do
        slice.each { |entry, index| imported += 1 if import_entry(entry, index: index) }
      end
      processed += slice.size
      say_progress(processed, imported, data.size)
    end
  rescue KeyError => error
    raise ImportError, "Invalid HSK entry: missing #{error.key}"
  end

  private

  attr_reader :path, :hsk_level

  def import_entry(entry, index:)
    character = entry.fetch("simplified")

    flashcard = Flashcard.find_or_initialize_by(character: character)

    return false if flashcard.persisted?

    form = self.class.form_for(entry)

    flashcard.assign_attributes(
      pinyin: form.fetch("transcriptions").fetch("pinyin"),
      meaning: form.fetch("meanings").join("; "),
      story: nil,
      story_status: "missing",
      source: SOURCE,
      hsk_level: hsk_level
      # next_review_at is left unset: the model's create callback makes
      # imported cards due immediately; the daily cap paces arrivals.
    )

    # Concurrent imports of the same character both miss the
    # find_or_initialize_by SELECT and race on INSERT. The
    # loser's unique violation must not poison the whole
    # import transaction, so save under a savepoint and
    # treat a lost race as "already imported".
    Flashcard.transaction(requires_new: true) { flashcard.save! }
    backfill_radical(entry)
    true
  rescue ActiveRecord::RecordNotUnique
    false # lost a race with a concurrent import; already counted by the winner
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

  # Progress to stdout so a detached prod run can be polled from the log.
  def say_progress(processed, imported, total)
    puts format("  %s: %d/%d entries processed, %d imported", File.basename(path), processed, total, imported)
  end
end
