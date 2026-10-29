module Audio
  # Builds SSML from a card's hanzi, validated against its own pinyin so
  # the audio can never contradict the card: the syllable count is
  # segmented from the card's pinyin and must match the hanzi (erhua's
  # merged -r being the one legal exception) before anything renders.
  #
  # Phoneme hinting (reading the pinyin via <phoneme>) is deliberately
  # NOT used: verified empirically on 2026-10-29 against the
  # northeurope endpoint that EVERY <phoneme> element is rejected with a
  # 400 and an empty body — sapi and ipa alphabets alike, hanzi or
  # pinyin inner text — while plain hanzi text inside the same prosody
  # wrapper renders fine. Readings therefore come from each voice's
  # built-in lexicon; polyphone quality is a listening-pass concern,
  # checked per voice during validation.
  class SsmlBuilder
    class MismatchError < StandardError; end

    # Voices to A/B in the validation pass. First one is the default.
    VOICE_CANDIDATES = {
      "xiaoxiao" => "zh-CN-XiaoxiaoNeural",
      "yunxi" => "zh-CN-YunxiNeural",
      "xiaoyi" => "zh-CN-XiaoyiNeural"
    }.freeze
    DEFAULT_VOICE = "zh-CN-XiaoxiaoNeural"

    # Drill audio wants clear and slightly slow, not conversational.
    DEFAULT_RATE = "-10%"

    def initialize(voice: DEFAULT_VOICE, rate: DEFAULT_RATE)
      @voice = voice
      @rate = rate
    end

    def call(flashcard)
      hanzi_count = flashcard.character.scan(/\p{Han}/).size
      syllables = PinyinNormalizer.syllables(flashcard.pinyin, target_count: hanzi_count)

      # Erhua is the one legitimate mismatch: 儿 is written as a hanzi but
      # pronounced as the -r rhotacization of the previous syllable, so a
      # card ending in 儿 comes back one syllable short. Anything else
      # means the pinyin does not describe this word.
      if syllables.size != hanzi_count && !(flashcard.character.end_with?("儿") && syllables.size == hanzi_count - 1)
        raise MismatchError, "#{flashcard.character}: #{syllables.size} syllables (#{syllables.join(' ')}) vs #{hanzi_count} hanzi from pinyin '#{flashcard.pinyin}'"
      end

      <<~SSML
        <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN"><voice name="#{@voice}"><prosody rate="#{@rate}">#{flashcard.character}</prosody></voice></speak>
      SSML
    end
  end
end
