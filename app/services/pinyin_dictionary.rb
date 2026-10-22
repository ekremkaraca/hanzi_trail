# Reads the plain-text pinyin map published by mozillazg/pinyin-data
# (MIT, derived from the Unicode Unihan database): one line per
# character, "U+4E00: yī,yí,yì  # 一", primary reading first and
# alternatives comma-separated.
#
# Besides the readings for a single character it builds a syllable
# inventory, which is what lets a card's pinyin be split back into one
# syllable per character: the card stores the word ("Zhōngguó"), the
# dictionary knows the parts.
class PinyinDictionary
  TONE_MARKED = /[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜǹńň]/.freeze

  def self.load(path)
    new(path: path)
  end

  # Tone-free, case-insensitive comparison key: Unicode decomposition
  # followed by dropping combining marks turns "Zhōng", "zhǒng" and
  # "zhong" into the same key, which is what separates "wrong reading"
  # from "same reading, different tone".
  def self.base_form(value)
    value.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase
  end

  def self.tone_marked?(value)
    value.match?(TONE_MARKED)
  end

  def initialize(path:)
    raise ArgumentError, "Pinyin dictionary not found: #{path}" unless File.file?(path)

    @path = path
    @readings = {}
    @syllables = Set.new
    @base_syllables = Set.new
    parse
  end

  # The exact string the dictionary stores for a character, commas and
  # all, so an importer can persist it unchanged.
  def raw_for(character)
    @readings[character]
  end

  def readings_for(character)
    @readings.fetch(character, "").split(",")
  end

  # Splits pinyin into one syllable per character, returning slices of
  # the original string so tone marks, capitalisation and neutral-tone
  # spellings survive untouched. Separators already present (spaces,
  # apostrophes) are ignored, so the result does not depend on how the
  # value happens to be spaced.
  #
  # Without a count the split is greedy, and greedy can misfire: 女儿
  # greedy-splits as "nǚé" before it discovers "nǚ" + "ér", so "Hánguó"
  # turns up "Háng" + "uó" rather than "Hán" + "guó". When a card's
  # character count is known, pass it — the split is then required to
  # produce exactly that many syllables, which settles those splits and
  # makes a card whose reading does not fit into its own character count
  # the finding the audit needs to report.
  #
  # Returns nil when no split into known syllables exists. Callers must
  # report that as unknown - guessing a split is how a wrong reading
  # gets written into good data.
  def segment(pinyin, count: nil)
    clean = pinyin.to_s.delete(" '’")
    return nil if clean.empty?

    if count
      split_exact(clean, 0, count, {})
    else
      greedy_split(clean)
    end
  end

  private

  attr_reader :path, :max_syllable_length

  def greedy_split(clean)
    syllables = []
    index = 0

    while index < clean.length
      candidate = match_at(clean, index)
      return nil if candidate.nil?

      syllables << candidate
      index += candidate.length
    end

    syllables
  end

  # Memoized depth-first split into exactly `count` syllables, longest
  # candidate tried first so a split agrees with greedy wherever greedy
  # already worked.
  def split_exact(clean, index, count, memo)
    key = [ index, count ]
    return memo[key] if memo.key?(key)

    memo[key] = if count.zero?
      index == clean.length ? [] : nil
    else
      split_longest_first(clean, index, count, memo)
    end
  end

  def split_longest_first(clean, index, count, memo)
    max = [ clean.length - index, max_syllable_length ].min

    max.downto(1) do |length|
      candidate = clean[index, length]
      next unless syllable?(candidate)

      rest = split_exact(clean, index + length, count - 1, memo)
      return [ candidate, *rest ] if rest
    end

    nil
  end

  # Tone-marked candidates must match a real toned reading exactly: a
  # base-form check would let "Xīān" pass as the single syllable "xian",
  # which is how 西安 came out as one syllable for two characters. The
  # base-form inventory only rescues unmarked spellings — what a neutral
  # tone or a tone-less transcript looks like.
  def syllable?(candidate)
    downcased = candidate.downcase
    return true if @syllables.include?(downcased)

    !self.class.tone_marked?(downcased) && @base_syllables.include?(base(downcased))
  end

  # Longest match wins, so "xian" reads as one syllable until something
  # forces the split. The cap comes from the data rather than a guessed
  # constant, because tone marks are single characters and do not
  # lengthen a syllable.
  def match_at(clean, index)
    max = [ clean.length - index, max_syllable_length ].min

    max.downto(1) do |length|
      candidate = clean[index, length]
      return candidate if syllable?(candidate)
    end

    nil
  end

  def base(value)
    self.class.base_form(value)
  end

  # "U+4E00: yī,yí,yì  # 一" -> { "一" => "yī,yí,yì" }
  def parse
    File.foreach(path) do |line|
      codepoint, comment = line.split("#", 2)
      next if comment.blank?

      codepoint, value = codepoint.split(":", 2)
      next if codepoint.blank? || value.blank?

      character = character_for(codepoint)
      next if character.nil?

      @readings[character] = value.strip
    end

    build_inventory
  end

  def character_for(codepoint)
    match = codepoint.strip.match(/\AU\+([0-9A-F]{4,6})\z/)
    return if match.nil?

    match[1].to_i(16).chr(Encoding::UTF_8)
  end

  def build_inventory
    @readings.each_value do |value|
      value.split(",").each do |reading|
        downcased = reading.downcase
        @syllables << downcased
        @base_syllables << base(reading)
      end
    end

    @max_syllable_length = (@syllables + @base_syllables).map(&:length).max || 1
  end
end
