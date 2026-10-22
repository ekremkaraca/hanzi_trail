class FixCardPinyinData < ActiveRecord::Migration[8.1]
  # Two curated cards held a word's pinyin on a one-character card. 电
  # carried 电话's reading and gloss, which is the word the card was
  # meant to teach (there was no 电话 card, while 电脑/电视/电影 each had
  # their own), and 鑫 carried a two-syllable typo for a single reading.
  #
  # Each repair is conditional on the card still holding the broken
  # values, so a curator who already corrected one is left alone.
  def up
    phone_card = Flashcard.find_by(character: "电")
    if phone_card && phone_card.pinyin == "diànhuà" && phone_card.meaning == "telephone"
      # Goes through the model so the character-entry relink runs: 话
      # needs linking and 电 must stay linked for 电脑, 电视 and friends.
      phone_card.update!(character: "电话")
    end

    Flashcard.where(character: "鑫", pinyin: "xīnmiǎo").update_all(pinyin: "xīn")
  end

  def down
    phone_card = Flashcard.find_by(character: "电话")
    if phone_card && phone_card.pinyin == "diànhuà" && phone_card.meaning == "telephone"
      phone_card.update!(character: "电")
    end

    Flashcard.where(character: "鑫", pinyin: "xīn").update_all(pinyin: "xīnmiǎo")
  end
end
