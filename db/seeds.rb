require_relative "seeds/flashcard"

FLASHCARD_SEEDS.each do |attrs|
  Flashcard.find_or_create_by(character: attrs.fetch(:character)) do |card|
    card.assign_attributes(attrs)
  end
end

puts "Seeded #{FLASHCARD_SEEDS.size} flashcards."
