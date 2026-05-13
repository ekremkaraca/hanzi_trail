require_relative "seeds/flashcard"

FLASHCARD_SEEDS.each do |attrs|
  Flashcard
    .find_or_initialize_by(character: attrs.fetch(:character))
    .update!(attrs)
end

puts "Seeded #{FLASHCARD_SEEDS.size} flashcards."
