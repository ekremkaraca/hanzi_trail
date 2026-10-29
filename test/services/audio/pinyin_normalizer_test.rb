require "test_helper"

module Audio
  class PinyinNormalizerTest < ActiveSupport::TestCase
    test "to_sapi converts diacritics to numbered pinyin" do
      assert_equal "wang3", PinyinNormalizer.to_sapi("wǎng")
      assert_equal "luo4", PinyinNormalizer.to_sapi("luò")
      assert_equal "ming2", PinyinNormalizer.to_sapi("míng")
    end

    test "to_sapi appends 5 for neutral-tone syllables" do
      # 名字's second syllable: the draft's shape was silently DROPPED.
      assert_equal "zi5", PinyinNormalizer.to_sapi("zi")
    end

    test "to_sapi passes numbered input through untouched" do
      # Stripping the digit is exactly the draft's silent-drop bug.
      assert_equal "xing2", PinyinNormalizer.to_sapi("xing2")
    end

    test "to_sapi renders ü as v per SAPI convention" do
      assert_equal "lv3", PinyinNormalizer.to_sapi("lǚ")
      assert_equal "nv3", PinyinNormalizer.to_sapi("nǚ")
    end

    test "to_sapi lowercases and returns nil for letterless input" do
      assert_equal "shu1", PinyinNormalizer.to_sapi("Shū")
      assert_nil PinyinNormalizer.to_sapi("，")
      assert_nil PinyinNormalizer.to_sapi("")
    end

    test "syllables splits joined intra-word syllables" do
      # 人工智能 stores "réngōng zhìnéng": no space between rén and gōng.
      assert_equal %w[ren2 gong1 zhi4 neng2], PinyinNormalizer.syllables("réngōng zhìnéng", target_count: 4)
    end

    test "syllables treats apostrophes as separators" do
      assert_equal %w[tu3 er3 qi2], PinyinNormalizer.syllables("Tǔ'ěrqí", target_count: 3)
    end

    test "syllables anchors segmentation on the hanzi count" do
      # Greedy-longest would read "xi'an" merged as one syllable; a
      # 2-hanzi anchor forces xi + an.
      assert_equal %w[xi1 an5], PinyinNormalizer.syllables("xī'an", target_count: 2)
    end

    test "syllables merges erhua into a rhotacized syllable" do
      # 哪儿 is 2 hanzi but one spoken syllable: the -r is the
      # rhotacization of nǎ, not a separate syllable.
      assert_equal %w[nar3], PinyinNormalizer.syllables("nǎr", target_count: 2)
      assert_equal %w[nar3], PinyinNormalizer.syllables("nǎ r", target_count: 2)
    end

    test "syllables ignores embedded tone digits" do
      # Corpus stores erhua neutral suffixes as digits: 没法儿 is "méifǎr5".
      assert_equal %w[mei2 far3], PinyinNormalizer.syllables("méifǎr5", target_count: 2)
    end

    test "syllables returns nil for unsegmentable input" do
      assert_nil PinyinNormalizer.syllables("xyzzy")
    end
  end
end
