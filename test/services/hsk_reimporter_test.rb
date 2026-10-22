require "test_helper"

class HskReimporterTest < ActiveSupport::TestCase
  setup do
    @path = Rails.root.join("test/fixtures/files/hsk_sense_selection.json")
  end

  test "repairs a card that still holds the headword values the importer wrote" do
    create_hsk_card(character: "书", pinyin: "Shū", meaning: "abbr. for 书经")

    report = HskReimporter.call(path: @path)

    card = Flashcard.find_by!(character: "书")

    assert_equal "shū", card.pinyin
    assert_equal "book; letter", card.meaning
    assert_equal [ "书" ], report.updated.map(&:character)
    assert_equal "Shū", report.updated.first.pinyin_from
    assert_equal "shū", report.updated.first.pinyin_to
  end

  test "leaves a curator-edited card alone" do
    create_hsk_card(character: "书", pinyin: "shū", meaning: "a book the curator wrote")
    # Values that match neither the headword nor the common sense cannot
    # have come from the importer, so they must be treated as curated.
    create_hsk_card(character: "那", pinyin: "nà", meaning: "that (edited)")

    report = HskReimporter.call(path: @path)

    card = Flashcard.find_by!(character: "书")

    assert_equal "shū", card.pinyin
    assert_equal "a book the curator wrote", card.meaning
    assert_includes report.edited, "书"
    assert_includes report.edited, "那"
    assert_empty report.updated
  end

  test "leaves a card alone when the headword is the entry's only form" do
    create_hsk_card(character: "中国", pinyin: "Zhōng guó", meaning: "China")

    report = HskReimporter.call(path: @path)

    card = Flashcard.find_by!(character: "中国")

    assert_equal "Zhōng guó", card.pinyin
    assert_equal "China", card.meaning
    assert_includes report.unchanged, "中国"
    assert_empty report.updated
  end

  test "reports cards that are absent from the file" do
    create_hsk_card(character: "酸奶", pinyin: "suān nǎi", meaning: "yogurt")

    report = HskReimporter.call(path: @path)

    assert_includes report.missing, "酸奶"
    assert_equal "suān nǎi", Flashcard.find_by!(character: "酸奶").pinyin
  end

  test "never touches curated cards" do
    Flashcard.create!(
      character: "书",
      pinyin: "shū",
      meaning: "curated card",
      source: "curated",
      next_review_at: Time.current
    )

    report = HskReimporter.call(path: @path)

    assert_equal "shū", Flashcard.find_by!(character: "书").pinyin
    # Fixture cards carry source hsk and are absent from this small file,
    # so only the lists that mean "something was written" must be empty.
    assert_empty report.updated
    assert_empty report.edited
    refute_includes report.missing, "书"
  end

  test "raises when file does not exist" do
    error = assert_raises(HskReimporter::ReimportError) do
      HskReimporter.call(path: Rails.root.join("test/fixtures/files/nonexistent.json"))
    end

    assert_match(/does not exist/, error.message)
  end

  test "raises when JSON is malformed" do
    error = assert_raises(HskReimporter::ReimportError) do
      HskReimporter.call(path: Rails.root.join("test/fixtures/files/hsk_malformed.json"))
    end

    assert_match(/Invalid JSON/, error.message)
  end

  test "raises when the data is not an array" do
    error = assert_raises(HskReimporter::ReimportError) do
      HskReimporter.call(path: Rails.root.join("test/fixtures/files/hsk_not_an_array.json"))
    end

    assert_match(/must be an array/, error.message)
  end

  private

  def create_hsk_card(character:, pinyin:, meaning:)
    Flashcard.create!(
      character: character,
      pinyin: pinyin,
      meaning: meaning,
      source: "hsk",
      hsk_level: "old-1",
      next_review_at: Time.current
    )
  end
end
