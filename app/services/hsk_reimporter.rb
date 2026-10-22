class HskReimporter
  class ReimportError < StandardError; end

  # Repairs cards a previous import wrote: their pinyin and meaning are
  # re-derived from the same file using the current form-selection rule.
  #
  # A card is only repaired when both values still equal what the old
  # headword-first rule wrote — that is how a curator edit is told apart
  # from a wrong import, since Flashcard has no provenance column. Cards
  # that were edited by hand, that are absent from the file, or that
  # already hold the right values are reported and left alone.
  Report = Struct.new(:updated, :edited, :missing, :unchanged, keyword_init: true)
  Change = Struct.new(:character, :pinyin_from, :pinyin_to, :meaning_from, :meaning_to, keyword_init: true)

  def self.call(path:, dry_run: false)
    new(path: path, dry_run: dry_run).call
  end

  def initialize(path:, dry_run: false)
    @path = path
    @dry_run = dry_run
  end

  def call
    raise ReimportError, "HSK file does not exist: #{path}" unless File.file?(path)

    report = Report.new(updated: [], edited: [], missing: [], unchanged: [])
    entries = index_entries(parse_json)

    # A dry run applies the same writes and rolls them back, so the
    # preview cannot drift from what a real run would do.
    Flashcard.transaction do
      Flashcard.where(source: "hsk").find_each do |card|
        repair(card, entries[card.character], report)
      end

      raise ActiveRecord::Rollback if dry_run
    end

    report
  rescue KeyError => error
    raise ReimportError, "Invalid HSK entry: missing #{error.key}"
  end

  private

  attr_reader :path, :dry_run

  def repair(card, entry, report)
    if entry.nil?
      report.missing << card.character
      return
    end

    unless pristine?(card, entry)
      report.edited << card.character
      return
    end

    form = HskImporter.form_for(entry)
    pinyin = form.fetch("transcriptions").fetch("pinyin")
    meaning = form.fetch("meanings").join("; ")

    if pinyin == card.pinyin && meaning == card.meaning
      report.unchanged << card.character
      return
    end

    change = Change.new(
      character: card.character,
      pinyin_from: card.pinyin,
      pinyin_to: pinyin,
      meaning_from: card.meaning,
      meaning_to: meaning
    )

    card.update!(pinyin: pinyin, meaning: meaning)
    report.updated << change
  end

  def pristine?(card, entry)
    form = entry.fetch("forms").first
    raise ReimportError, "Entry '#{entry.fetch("simplified")}' has an empty forms array" if form.nil?

    card.pinyin == form.fetch("transcriptions").fetch("pinyin") &&
      card.meaning == form.fetch("meanings").join("; ")
  end

  def index_entries(data)
    raise ReimportError, "HSK data must be an array" unless data.is_a?(Array)

    # The importer takes the first entry it sees for a character, so the
    # index must too or a repair could target a different entry than the
    # import did.
    data.each_with_object({}) { |entry, index| index[entry["simplified"]] ||= entry }
  end

  def parse_json
    JSON.parse(File.read(path))
  rescue JSON::ParserError => error
    raise ReimportError, "Invalid JSON: #{error.message}"
  end
end
