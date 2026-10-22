module CharacterEntries
  # Fills character-entry pinyin from a pinyin dictionary file.
  #
  # The dictionary is the plain-text map published by
  # mozillazg/pinyin-data (MIT, derived from the Unicode Unihan
  # database): one line per character, "U+4E00: yī  # 一", with the
  # primary reading first and alternatives comma-separated.
  #
  # Only entries without a pinyin are filled by default, so curated
  # values are never clobbered. `force` re-imports values a previous
  # dictionary run wrote and leaves manually curated ones — and entries
  # whose provenance is unknown — alone.
  class PinyinImporter
    DICTIONARY_SOURCE = "dictionary".freeze

    Report = Struct.new(:filled, :uncovered, :skipped, keyword_init: true) do
      def summary
        "#{filled} filled, #{uncovered} not in the dictionary, " \
          "#{skipped} left untouched"
      end
    end

    def self.import!(path:, dry_run: false, force: false)
      new(path:, dry_run:, force:).import!
    end

    def initialize(path:, dry_run: false, force: false)
      @path = path
      @dry_run = dry_run
      @force = force
    end

    def import!
      # DRY: file parsing, the per-character lookup and the missing-file
      # error now live in PinyinDictionary, shared with the card audit
      # that needs the same readings plus a syllable inventory.
      dictionary = PinyinDictionary.load(path)
      report = Report.new(filled: 0, uncovered: 0, skipped: 0)

      target_scope.find_each do |entry|
        reading = dictionary.raw_for(entry.character)

        if reading.blank?
          report.uncovered += 1
          next
        end

        if dry_run
          report.filled += 1
          next
        end

        # update_columns skips the model's "mark manual" callback and
        # the validations: the dictionary is the authority here, and the
        # write has to keep its dictionary provenance.
        entry.update_columns(
          pinyin: reading,
          pinyin_source: DICTIONARY_SOURCE,
          updated_at: Time.current
        )

        report.filled += 1
      end

      report
    end

    private

    attr_reader :path, :dry_run, :force

    # Blank entries by default. With force, only entries a previous
    # dictionary run wrote are re-imported — manual and unknown
    # provenance are never overwritten.
    def target_scope
      return CharacterEntry.where(pinyin_source: DICTIONARY_SOURCE) if force

      CharacterEntry.where(pinyin: [ nil, "" ])
    end
  end
end
