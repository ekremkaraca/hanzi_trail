require "test_helper"
require "rexml/document"

module Audio
  class SsmlBuilderTest < ActiveSupport::TestCase
    setup do
      @builder = SsmlBuilder.new
    end

    test "wraps the hanzi in well-formed SSML with the default voice" do
      card = Flashcard.new(character: "网络", pinyin: "wǎngluò")

      ssml = @builder.call(card)

      assert_includes ssml, 'voice name="zh-CN-XiaoxiaoNeural"'
      assert_includes ssml, 'rate="-10%"'
      assert_includes ssml, "网络"
      # Phoneme hinting is empirically rejected by the endpoint (400,
      # empty body) — the builder must never emit it.
      assert_not_includes ssml, "<phoneme"
      REXML::Document.new(ssml) # well-formed
    end

    test "voice slug picks the candidate voice" do
      builder = SsmlBuilder.new(voice: "zh-CN-YunxiNeural")
      card = Flashcard.new(character: "网", pinyin: "wǎng")

      assert_includes builder.call(card), 'voice name="zh-CN-YunxiNeural"'
    end

    test "erhua cards pass the pinyin guard with one merged syllable" do
      card = Flashcard.new(character: "哪儿", pinyin: "nǎr")

      assert_includes @builder.call(card), "哪儿"
    end

    test "syllable count that contradicts the hanzi is a hard error" do
      card = Flashcard.new(character: "网络", pinyin: "wǎng")

      error = assert_raises(SsmlBuilder::MismatchError) { @builder.call(card) }
      assert_match(/网络/, error.message)
    end
  end
end
