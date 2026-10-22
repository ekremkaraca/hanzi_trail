require "test_helper"

class PinyinDictionaryTest < ActiveSupport::TestCase
  FIXTURE = Rails.root.join("test/fixtures/files/pinyin_sample.txt")

  setup do
    @dictionary = PinyinDictionary.load(FIXTURE)
  end

  test "stores the dictionary value verbatim for importers" do
    assert_equal "jī,qī", @dictionary.raw_for("机")
    assert_nil @dictionary.raw_for("瞎")
  end

  test "reads the primary as the first of the comma-separated readings" do
    assert_equal [ "jī", "qī" ], @dictionary.readings_for("机")
    assert_empty @dictionary.readings_for("瞎")
  end

  test "keeps tone marks and capitalisation of the input in the split" do
    assert_equal [ "Zhōng", "guó" ], @dictionary.segment("Zhōngguó", count: 2)
  end

  test "splits tone-marked input on exact readings only" do
    # "Xīān" glued together must not pass as the single syllable 先
    # (xiān, whose base form is the same string) - the marks make
    # precisely where the two readings sit visible.
    assert_equal [ "Xī", "ān" ], @dictionary.segment("Xīān")
  end

  test "rescues unmarked spellings through their base form" do
    assert_equal [ "xǐ", "huan" ], @dictionary.segment("xǐhuan", count: 2)
  end

  test "backtracks so a handwriting fits the character count" do
    # Greedy splits 韩国 as "Háng" + "uó"; only "Hán" + "guó" has two
    # known syllables, and the count makes the difference findable.
    assert_equal [ "Hán", "guó" ], @dictionary.segment("Hánguó", count: 2)
  end

  test "reports nothing when the reading cannot fill the character count" do
    assert_nil @dictionary.segment("diànhuà", count: 1)
  end

  test "separators already present do not change the split" do
    assert_equal [ "Zhōng", "guó" ], @dictionary.segment("Zhōng guó", count: 2)
    assert_equal [ "xǐ", "huan" ], @dictionary.segment("xǐ huan", count: 2)
  end

  test "strips tone marks to a shared key" do
    assert_equal "zhong", PinyinDictionary.base_form("Zhōng")
    assert_equal "nu", PinyinDictionary.base_form("nǚ")
    assert_equal "jing", PinyinDictionary.base_form("jǐng")
  end

  test "classifies syllables as tone-marked or not" do
    assert PinyinDictionary.tone_marked?("bú")
    refute PinyinDictionary.tone_marked?("bu")
    refute PinyinDictionary.tone_marked?("zhong")
  end

  test "raises when the file does not exist" do
    error = assert_raises(ArgumentError) { PinyinDictionary.load("missing/nope.txt") }

    assert_match(/not found/, error.message)
  end
end
