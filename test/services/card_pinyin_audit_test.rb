require "test_helper"

class CardPinyinAuditTest < ActiveSupport::TestCase
  DICTIONARY = Rails.root.join("test/fixtures/files/pinyin_sample.txt")

  test "reports a positional reading the dictionary does not list" do
    card = create_card(character: "电", pinyin: "zhōng")

    report = CardPinyinAudit.call(path: DICTIONARY)

    assert_finding(report, character: card.character, kind: :reading,
                            detail: "'zhōng' is not a reading of '电'")
    assert_empty report.respaced
  end

  test "reports the character count when the reading cannot fit it" do
    card = create_card(character: "电", pinyin: "diànhuà")

    report = CardPinyinAudit.call(path: DICTIONARY)

    assert_finding(report, character: card.character, kind: :count,
                            detail: "2 syllables for 1 character(s)")
  end

  test "reports a transcript the dictionary cannot parse at all" do
    card = create_card(character: "机", pinyin: "abc")

    report = CardPinyinAudit.call(path: DICTIONARY)

    assert_finding(report, character: card.character, kind: :unsegmentable,
                            detail: "cannot be split into known syllables")
  end

  test "sorts a written tone from a tone-less spelling" do
    create_card(character: "机", pinyin: "qi")
    feed = create_card(character: "喂", pinyin: "wéi")

    report = CardPinyinAudit.call(path: DICTIONARY)

    assert_finding(report, character: "机", kind: :neutral,
                            detail: "'qi' has no tone mark; the dictionary lists qī")
    assert_finding(report, character: feed.character, kind: :tone,
                            detail: "'wéi' differs in tone from 'wèi'")
  end

  test "flags an unspaced multi-character reading until asked to fix it" do
    card = create_card(character: "中国", pinyin: "Zhōngguó")

    unasked = CardPinyinAudit.call(path: DICTIONARY)

    assert_finding(unasked, character: card.character, kind: :spacing,
                            detail: "no separator between the syllables")
    assert_equal "Zhōngguó", card.reload.pinyin

    asked = CardPinyinAudit.call(path: DICTIONARY, fix_spacing: true)

    assert_equal "Zhōng guó", card.reload.pinyin
    # Other fixture cards are not covered by the small sample dictionary
    # and keep finding their own reasons, so scope to this card.
    assert_finding_absent(asked, character: card.character)
    assert_equal 1, asked.respaced.size
    assert_equal "Zhōng guó", asked.respaced.first.to
  end

  test "leaves a card that already has a separator alone" do
    card = create_card(character: "中国", pinyin: "Zhōng guó")

    report = CardPinyinAudit.call(path: DICTIONARY)

    assert_finding_absent(report, character: card.character)
  end

  test "never re-spaces a card whose split fails the character count" do
    create_card(character: "电", pinyin: "diànhuà")

    report = CardPinyinAudit.call(path: DICTIONARY, fix_spacing: true)

    assert_equal "diànhuà", Flashcard.find_by!(character: "电").pinyin
    assert_empty report.respaced
  end

  test "a dry run reports the change without writing it" do
    card = create_card(character: "中国", pinyin: "Zhōngguó")

    report = CardPinyinAudit.call(path: DICTIONARY, fix_spacing: true, dry_run: true)

    assert_equal "Zhōngguó", card.reload.pinyin
    assert_equal "Zhōng guó", report.respaced.first.to
  end

  test "raises when the file does not exist" do
    error = assert_raises(ArgumentError) do
      CardPinyinAudit.call(path: Rails.root.join("test/fixtures/files/nonexistent.txt"))
    end

    assert_match(/not found/, error.message)
  end

  private

  def create_card(character:, pinyin:)
    Flashcard.create!(character: character, pinyin: pinyin, meaning: "n/a")
  end

  def assert_finding(report, character:, kind:, detail:)
    finding = report.findings.find { |f| f.character == character && f.kind == kind }
    assert finding, "no #{kind} finding for #{character} in #{report.findings.inspect}"
    assert_equal detail, finding.detail
  end

  def assert_finding_absent(report, character:)
    assert_empty report.findings.select { |f| f.character == character }
  end
end
