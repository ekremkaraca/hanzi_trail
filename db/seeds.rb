require_relative "seeds/flashcard"

FLASHCARD_SEEDS.each do |attrs|
  Flashcard.find_or_create_by(character: attrs.fetch(:character)) do |card|
    card.assign_attributes(attrs)
    card.next_review_at ||= Time.current
    card.difficulty ||= "new"
    card.review_count ||= 0
  end
end

puts "Seeded #{FLASHCARD_SEEDS.size} flashcards."
puts "Importing HSK old-1 flashcards..."

HskImporter.new(
  path: Rails.root.join("vendor/datasets/hsk/old/1.json"),
  hsk_level: "old-1"
).call

puts "HSK old-1 import completed."
puts "Linking character entries..."

# HskImporter already linked the cards it imported; only curated seed rows
# (and any strays) still need links. Re-linking everything would destroy and
# recreate every join row on each db:seed run.
Flashcard.where.missing(:flashcard_characters).find_each do |flashcard|
  CharacterLinker.call(flashcard)
end

puts "Done."
