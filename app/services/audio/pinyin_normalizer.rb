module Audio
  # Converts the app's diacritic pinyin ("wǎngluò", "míngzi") into the
  # numbered form Azure's SAPI <phoneme> alphabet wants ("wang3luo4",
  # "ming2zi5"), and segments multi-syllable words into syllables.
  #
  # Two correctness properties the drill app depends on:
  # - every syllable gets a tone digit (neutral = "5"), so no syllable is
  #   ever silently dropped from SSML;
  # - segmentation validates against a real Mandarin syllable chart, not
  #   initials×finals, so "réngōng" segments re+gōng, never réng+ong.
  class PinyinNormalizer
    # Marked vowel => [base vowel, tone digit]. ǖ-ǜ render as "v" (the
    # SAPI convention for lü/nü); the validation pass should listen to
    # 女/绿/旅 to confirm the voice agrees.
    TONE_MARKS = {
      "ā" => %w[a 1], "á" => %w[a 2], "ǎ" => %w[a 3], "à" => %w[a 4],
      "ē" => %w[e 1], "é" => %w[e 2], "ě" => %w[e 3], "è" => %w[e 4],
      "ī" => %w[i 1], "í" => %w[i 2], "ǐ" => %w[i 3], "ì" => %w[i 4],
      "ō" => %w[o 1], "ó" => %w[o 2], "ǒ" => %w[o 3], "ò" => %w[o 4],
      "ū" => %w[u 1], "ú" => %w[u 2], "ǔ" => %w[u 3], "ù" => %w[u 4],
      "ǖ" => %w[v 1], "ǘ" => %w[v 2], "ǚ" => %w[v 3], "ǜ" => %w[v 4]
    }.freeze

    # "wǎng" -> "wang3"; "wang3" passes through; "de" -> "de5" (neutral).
    # Returns nil for input with no letters (punctuation, empty).
    def self.to_sapi(syllable)
      new(syllable).to_sapi
    end

    # Segments a pinyin WORD ("réngōng", "Tǔ'ěrqí", "míngzi") into
    # per-syllable NUMBERED strings. The corpus stores some words without
    # intra-word spaces, so a whitespace split undercounts syllables by
    # exactly the syllables that matter (17 of 4,273 cards).
    #
    # `target_count` (the card's hanzi count) anchors the segmentation:
    # when several chart-valid splits exist ("xian" = xian | xi+an), the
    # split matching the hanzi count wins.
    def self.syllables(word, target_count: nil)
      words = word.to_s.downcase.split(/[\s'\u2019]+/).compact_blank
      return [] if words.empty?

      if words.size == 1
        segment_word(words.first, target_count: target_count)
      else
        # Segment per token first; if any token resists (or the total
        # misses the anchor), re-segment the joined string, where the
        # anchor disambiguates across the removed separators.
        segments = words.map { |w| segment_word(w) }
        total = segments.sum(&:size) if segments.all?
        if segments.all? && (!target_count || total == target_count)
          segments.flatten
        else
          segment_word(words.join, target_count: target_count)
        end
      end
    end

    # Greedy-longest segmentation; nil when the word cannot be split into
    # chart-valid syllables at all.
    def self.segment_word(word, target_count: nil)
      base = +""
      tones = []
      word.each_char do |ch|
        if TONE_MARKS.key?(ch)
          base << TONE_MARKS[ch][0]
          tones << TONE_MARKS[ch][1]
        elsif ch.match?(/[a-z]/)
          base << ch
          tones << nil
        elsif ch.match?(/\d/)
          # Tone digits inside words ("méifǎr5") carry tone info the
          # diacritics already encode or a neutral suffix; dropping them
          # keeps segmentation alive and the syllable defaults to 5.
          tones << nil
        else
          return nil # non-letters mean malformed pinyin, not a syllable
        end
      end
      return nil if base.empty?

      candidates = valid_splits(base, tones)
      return nil if candidates.empty?

      if target_count
        candidates.find { |syls| syls.size == target_count } ||
          # Off-target fallback keeps rendering possible for data that
          # segmentation can't reconcile (erhua: 哪儿 is 2 hanzi but one
          # rhotacized syllable); the builder's guard still surfaces it
          # rather than rendering contradicting audio.
          candidates.min_by { |syls| (syls.size - target_count).abs }
      else
        candidates.max_by(&:size)
      end
    end

    # All chart-valid ways to split `base` into syllables, each carrying
    # its first tone mark (or "5" for neutral). Backtracking over the
    # syllable chart; word length is ≤ ~10 letters, so this stays cheap.
    def self.valid_splits(base, tones)
      results = []
      walk = lambda do |pos, acc|
        if pos == base.length
          results << acc
          return
        end
        # Longest syllable first so greedy consumers get real words.
        (base.length - pos).downto(1) do |len|
          chunk = base[pos, len]
          next unless valid_syllable?(chunk)

          tone = tones[pos, len].compact.first || "5"
          walk.call(pos + len, acc + [[chunk, tone]])
        end
      end
      walk.call(0, [])
      results.map { |syls| syls.map { |s, t| s + t } }
    end

    # The standard Hanyu Pinyin syllable chart, grouped by initial class
    # because initials strongly constrain their finals (zh never takes
    # "in", j/q/x never take true "u", zero-initial syllables are a fixed
    # set). Erhua adds a trailing r to any chart syllable.
    ZERO_INITIAL = %w[a o e ai ei ao ou an en ang eng er
                      yi ya ye yao you yan yin yang ying yong
                      wu wa wo wai wei wan wen wang
                      yu yue yuan yun].freeze
    BPMF = %w[a o e ai ei ao ou an en ang eng
              i ie iao iu ian in iang ing
              u uo ui un].freeze
    # n/l additionally take the ü written forms (nv, nve, nvan...) below.
    DTNL = %w[a e ai ei ao ou an en ang eng
              i ia ie iao iu ian in iang ing
              u uo ui uan un uang ong v ve van vn].freeze
    GKH = %w[a e ai ei ao ou an en ang eng
             u ua uo uai ui uan un uang ong].freeze
    JQX = %w[i ia iao ie iu ian in iang ing iong
             u ue uan un].freeze # "u" here is ü (ju = jü)
    ZCS = %w[a e ai ei ao ou an en ang eng
             u uo uai ui uan un ong i].freeze
    ZHCSR = %w[a e ai ei ao ou an en ang eng
               u ua uo uai ui uan un uang ong i].freeze

    CHART = {
      "" => ZERO_INITIAL,
      "b" => BPMF, "p" => BPMF, "m" => BPMF, "f" => BPMF,
      "d" => DTNL, "t" => DTNL, "n" => DTNL, "l" => DTNL,
      "g" => GKH, "k" => GKH, "h" => GKH,
      "j" => JQX, "q" => JQX, "x" => JQX,
      "z" => ZCS, "c" => ZCS, "s" => ZCS,
      "zh" => ZHCSR, "ch" => ZHCSR, "sh" => ZHCSR, "r" => ZHCSR
    }.freeze

    def self.valid_syllable?(chunk)
      # Erhua suffix: any chart syllable plus "r" (but "r" alone is not
      # one) — 哪儿 "nar", 没法儿 "far".
      return true if chunk.length > 1 && chunk.end_with?("r") && valid_syllable?(chunk[0..-2])

      # Longest initials first so "zh" wins over "z".
      CHART.each_key do |initial|
        next if initial.empty?
        next unless chunk.start_with?(initial)

        return true if CHART[initial].include?(chunk[initial.length..])
      end
      CHART[""].include?(chunk)
    end

    def initialize(syllable)
      @syllable = syllable.to_s.downcase.strip
    end

    def to_sapi
      return @syllable if numbered?

      base = +""
      tone = "5"
      @syllable.each_char do |ch|
        if TONE_MARKS.key?(ch)
          base << TONE_MARKS[ch][0]
          tone = TONE_MARKS[ch][1]
        elsif ch.match?(/[a-z]/)
          base << ch
        end
        # Anything else (punctuation, stray digits) is dropped: a digit
        # here would be malformed input, and emitting it would contradict
        # the tone we just derived from the diacritic.
      end
      base.empty? ? nil : base + tone
    end

    private

    # Already-numbered input ("wang3") passes through untouched: it is a
    # rare, deliberate shape (forced validation readings), and stripping
    # its digit the way the draft did is what silently dropped neutral
    # syllables there.
    def numbered?
      @syllable.match?(/\A[a-zü]+\d\z/)
    end
  end
end
