class HskImporter
  SOURCE = "hsk".freeze

  def initialize(path:, hsk_level:)
    @path = path
    @hsk_level = hsk_level
  end

  def call
    records.each { |entry| import_entry(entry) }
  end

  private

  attr_reader :path, :hsk_level

  def records
    raise "HSK data file not found: #{path}" unless File.exist?(path)
    JSON.parse(File.read(path))
  rescue JSON::ParserError => e
    raise "Failed to parse HSK data file: #{e.message}"
  end

  def import_entry(entry)
    character = entry.fetch("simplified")

    flashcard = Flashcard.find_or_initialize_by(character: character)

    return if flashcard.persisted?

    form = entry.fetch("forms").first

    flashcard.assign_attributes(
      pinyin: form.fetch("transcriptions").fetch("pinyin"),
      meaning: form.fetch("meanings").join("; "),
      story: nil,
      source: SOURCE,
      hsk_level: hsk_level,
      next_review_at: Time.current
    )

    flashcard.save!
  end
end
