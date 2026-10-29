require "test_helper"

module Audio
  class SsmlBuilderTest < ActiveSupport::TestCase
    setup do
      @builder = SsmlBuilder.new
    end

    test "builds well-formed SSML with a phoneme hint per syllable" do
      card = Flashcard.new(character: "网络", pinyin: "wǎngluò")

      ssml = @builder.call(card)

      assert_includes ssml, 'voice name="zh-CN-XiaoxiaoNeural"'
      assert_includes ssml, 'rate="-10%"'
      assert_includes ssml, '<phoneme alphabet="sapi" ph="wang3">wang3</phoneme>'
      assert_includes ssml, '<phoneme alphabet="sapi" ph="luo4">luo4</phoneme>'
    end

    test "lexicon mode feeds the hanzi and no phoneme hints" do
      builder = SsmlBuilder.new(hint: SsmlBuilder::HINT_NONE)
      card = Flashcard.new(character: "网络", pinyin: "wǎngluò")

      ssml = builder.call(card)

      assert_includes ssml, "网络"
      assert_not_includes ssml, "<phoneme"
    end

    test "neutral-tone syllables keep their place and digit" do
      # 名字: the draft dropped "zi" entirely.
      card = Flashcard.new(character: "名字", pinyin: "míngzi")

      ssml = @builder.call(card)

      assert_includes ssml, 'ph="ming2"'
      assert_includes ssml, 'ph="zi5"'
    end

    test "erhua cards render one merged rhotacized syllable" do
      card = Flashcard.new(character: "哪儿", pinyin: "nǎr")

      ssml = @builder.call(card)

      assert_includes ssml, 'ph="nar3"'
    end

    test "syllable count that contradicts the hanzi is a hard error" do
      card = Flashcard.new(character: "网络", pinyin: "wǎng")

      error = assert_raises(SsmlBuilder::MismatchError) { @builder.call(card) }
      assert_match(/网络/, error.message)
    end

    test "voice slug picks the candidate voice" do
      builder = SsmlBuilder.new(voice: "zh-CN-YunxiNeural")
      card = Flashcard.new(character: "网", pinyin: "wǎng")

      assert_includes builder.call(card), 'voice name="zh-CN-YunxiNeural"'
    end
  end
end
