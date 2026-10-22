require "test_helper"

class CharacterEntryTest < ActiveSupport::TestCase
  test "requires character" do
    entry = CharacterEntry.new(character: "")

    assert_not entry.valid?
  end

  test "requires unique character" do
    CharacterEntry.create!(character: "河")

    duplicate = CharacterEntry.new(character: "河")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:character], "has already been taken"
  end

  # Regression: deleting an in-use entry stripped its hanzi from every card that
  # contained it, permanently (the card's character never changes, so Flashcard's
  # relink callback never fires again and no UI can re-add the hanzi).
  test "an entry a card still needs is not deletable" do
    # Fixtures bypass callbacks, so build the join via the model API.
    card = Flashcard.create!(character: "中国", pinyin: "zhōngguó", meaning: "China")
    entry = CharacterEntry.find_by!(character: "国")

    assert_includes entry.required_by_cards, card
    assert_not entry.deletable?
  end

  test "an entry no card needs is deletable" do
    entry = CharacterEntry.create!(character: "鑫")

    assert_empty entry.required_by_cards
    assert entry.deletable?
  end

  test "required_by_cards matches only cards containing the exact hanzi" do
    card = Flashcard.create!(character: "中国", pinyin: "zhōngguó", meaning: "China")

    assert_equal [ card ], CharacterEntry.new(character: "国").required_by_cards.to_a
    assert_empty CharacterEntry.new(character: "日").required_by_cards
  end

  test "required_by_cards treats LIKE wildcards as literals" do
    Flashcard.create!(character: "中国", pinyin: "zhōngguó", meaning: "China")

    # A '%' entry must not match every card via the LIKE pattern.
    assert_empty CharacterEntry.new(character: "%").required_by_cards
  end

  test "marks the pinyin source manual when a curator changes the pinyin" do
    entry = CharacterEntry.create!(character: "河", pinyin: "hé")

    assert_equal "manual", entry.pinyin_source

    # Saving without touching the pinyin keeps the current source.
    entry.update!(pinyin_source: "dictionary")
    assert_equal "dictionary", entry.pinyin_source

    entry.update!(pinyin: "hè")
    assert_equal "manual", entry.pinyin_source
  end

  test "splits readings into a primary reading and alternates" do
    entry = CharacterEntry.new(character: "重", pinyin: "chóng,zhǎng")

    assert_equal [ "chóng", "zhǎng" ], entry.pinyin_readings
    assert_equal "chóng", entry.primary_pinyin
    assert_equal [ "zhǎng" ], entry.alternate_pinyin
  end
end
