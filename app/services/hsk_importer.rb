class HskImporter
  class ImportError < StandardError; end

  SOURCE = "hsk".freeze

  def self.import!(path:, level: nil, hsk_level: nil)
    new(path: path, hsk_level: hsk_level || level).import!
  rescue ImportError
    raise
  rescue RuntimeError => error
    raise ImportError, error.message
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
    raise "Entry '#{character}' has an empty forms array" if form.nil?

    flashcard.assign_attributes(
      pinyin: form.fetch("transcriptions").fetch("pinyin"),
      meaning: form.fetch("meanings").join("; "),
      story: nil,
      story_status: "missing",
      source: SOURCE,
      hsk_level: hsk_level,
      next_review_at: Time.current
    )

    flashcard.save!
  end

  def parse_json
    JSON.parse(File.read(path))
  rescue JSON::ParserError => error
    raise ImportError, "Invalid JSON: #{error.message}"
  end

  def first_form_for(entry)
    unless entry.is_a?(Array) && entry.first.is_a?(Hash)
      raise ImportError, "Invalid HSK entry: forms must contain at least one form"
    end

    entry.first
  end
end
