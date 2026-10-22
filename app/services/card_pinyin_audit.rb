# Compares every card's pinyin with the pinyin dictionary and reports
# what does not line up. It is a reporting tool first: readings are
# never rewritten from the dictionary, because a card may hold a
# legitimate reading the dictionary does not list (喂 "wéi", the phone
# interjection) or an in-word tone the dictionary writes differently.
#
# The one write it can do is spacing: with FIX_SPACING it separates the
# syllables of a multi-character card that has no separator at all, so
# 中国 reads "Zhōng guó" like the imported cards do. It only touches a
# card whose split yields exactly one syllable per character, so a
# card with a genuinely wrong reading is reported instead of mangled.
class CardPinyinAudit
  Finding = Struct.new(:character, :pinyin, :kind, :detail, keyword_init: true)
  Change = Struct.new(:character, :from, :to, keyword_init: true)
  Report = Struct.new(:checked, :findings, :respaced, keyword_init: true)

  def self.call(path:, fix_spacing: false, dry_run: false)
    new(path: path, fix_spacing: fix_spacing, dry_run: dry_run).call
  end

  def initialize(path:, fix_spacing: false, dry_run: false)
    @path = path
    @fix_spacing = fix_spacing
    @dry_run = dry_run
    @report = Report.new(checked: 0, findings: [], respaced: [])
  end

  def call
    @dictionary = PinyinDictionary.load(path)

    # A dry run writes and rolls back, so the preview cannot disagree
    # with the real run about what would change.
    Flashcard.transaction do
      Flashcard.find_each { |card| audit(card) }
      raise ActiveRecord::Rollback if dry_run
    end

    report
  end

  private

  attr_reader :path, :fix_spacing, :dry_run, :report, :dictionary

  def audit(card)
    report.checked += 1
    syllables = dictionary.segment(card.pinyin, count: card.character.length)

    if syllables.nil?
      return explain_split_failure(card)
    end

    separate(card, syllables)
    compare_readings(card, syllables)
  end

  # The targeted split failing means the reading cannot be made to fit
  # the character count at all. Greedy gives what the transcript does
  # parse into, or states that nothing about it is recognisable.
  def explain_split_failure(card)
    greedy = dictionary.segment(card.pinyin)

    if greedy
      finding(
        card, :count,
        "#{greedy.length} syllables for #{card.character.length} character(s)"
      )
    else
      finding(card, :unsegmentable, "cannot be split into known syllables")
    end
  end

  def separate(card, syllables)
    return unless card.character.length > 1
    return if card.pinyin.match?(/[ '’]/)

    unless fix_spacing
      return finding(card, :spacing, "no separator between the syllables")
    end

    respaced = syllables.join(" ")
    report.respaced << Change.new(character: card.character, from: card.pinyin, to: respaced)

    card.update!(pinyin: respaced) unless dry_run
  end

  # Positions are trusted only because the count already matched: each
  # syllable is held against the character sitting under it. A
  # positional agreement may be exact, a neutral tone the dictionary
  # writes with a mark (weak), or a different tone outright — the last
  # is the class worth looking at, since that is where typo-style errors
  # and tone-sandhi words both live.
  def compare_readings(card, syllables)
    card.character.chars.zip(syllables).each do |character, syllable|
      readings = dictionary.readings_for(character)
      next if readings.empty?

      key = syllable.downcase
      next if readings.include?(key)

      same_base = readings.select { |reading| base(reading) == base(key) }

      if same_base.empty?
        finding(card, :reading, "'#{syllable}' is not a reading of '#{character}'")
      elsif PinyinDictionary.tone_marked?(key)
        finding(
          card, :tone,
          "'#{syllable}' differs in tone from #{same_base.map { |reading| "'#{reading}'" }.join(", ")}"
        )
      else
        finding(
          card, :neutral,
          "'#{syllable}' has no tone mark; the dictionary lists #{same_base.join(", ")}"
        )
      end
    end
  end

  def base(value)
    PinyinDictionary.base_form(value)
  end

  def finding(card, kind, detail)
    report.findings << Finding.new(
      character: card.character,
      pinyin: card.pinyin,
      kind: kind,
      detail: detail
    )
  end
end
