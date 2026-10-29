module Audio
  # Builds Azure SSML from a card's OWN pinyin, so audio can never
  # contradict the card. The syllable count is validated against the
  # hanzi before rendering: a pinyin that segments to a different number
  # of syllables than the card teaches would produce audio for a
  # different word — that's a hard error, not a render.
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
    DEFAULT_PITCH = "+0Hz"

    # :all hints every syllable with the card's own pinyin (guarantees
    # polyphone readings match the card, at some prosody cost);
    # :none feeds the raw hanzi and lets the voice's lexicon decide.
    # The validation pass A/Bs the two modes before batch rendering.
    HINT_ALL = :all
    HINT_NONE = :none

    def initialize(voice: DEFAULT_VOICE, rate: DEFAULT_RATE, pitch: DEFAULT_PITCH, hint: HINT_ALL)
      @voice = voice
      @rate = rate
      @pitch = pitch
      @hint = hint
    end

    def call(flashcard)
      hanzi_count = flashcard.character.scan(/\p{Han}/).size
      syllables = PinyinNormalizer.syllables(flashcard.pinyin, target_count: hanzi_count)

      # Erhua is the one legitimate mismatch: 儿 is written as a hanzi but
      # pronounced as the -r rhotacization of the previous syllable, so a
      # card ending in 儿 may come back one syllable short. Anything else
      # means the pinyin does not describe this word.
      if syllables.size != hanzi_count && !(flashcard.character.end_with?("儿") && syllables.size == hanzi_count - 1)
        raise MismatchError, "#{flashcard.character}: #{syllables.size} syllables (#{syllables.join(' ')}) vs #{hanzi_count} hanzi from pinyin '#{flashcard.pinyin}'"
      end

      # In hint mode the visible text is the numbered pinyin (what the
      # <phoneme> tags pin); in lexicon mode it is the hanzi itself.
      body =
        if @hint == HINT_ALL
          syllables.map { |syl| %{<phoneme alphabet="sapi" ph="#{syl}">#{syl}</phoneme>} }.join(" ")
        else
          flashcard.character
        end

      <<~SSML
        <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN"><voice name="#{@voice}"><prosody rate="#{@rate}" pitch="#{@pitch}">#{body}</prosody></voice></speak>
      SSML
    end
  end
end
