namespace :character_entries do
  desc "Create character links for all flashcards"
  task link: :environment do
    Flashcard.find_each do |flashcard|
      CharacterLinker.call(flashcard)
    end

    puts "Linked characters for #{Flashcard.count} flashcards."
  end
end
