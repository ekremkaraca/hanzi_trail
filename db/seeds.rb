require_relative "seeds/flashcard"

FLASHCARD_SEEDS.each do |attrs|
  Flashcard.find_or_create_by(character: attrs.fetch(:character)) do |card|
    card.assign_attributes(attrs)
    card.next_review_at ||= Time.current
    card.difficulty ||= "new"
    card.review_count ||= 0
  end
end

Rails.logger.debug { "Seeded #{FLASHCARD_SEEDS.size} flashcards." }
Rails.logger.debug "Importing HSK 3.0 (new-1..new-5) flashcards..."

# Idempotent: HskImporter skips persisted characters, and due dates are
# staggered across months at import time (see STAGGER_CYCLE_DAYS), so
# re-running seeds never dumps a wall of new cards into today's queue.
(1..5).each do |level|
  HskImporter.new(
    path: Rails.root.join("vendor/datasets/hsk/new/#{level}.json"),
    hsk_level: "new-#{level}"
  ).call
end

Rails.logger.debug "HSK 3.0 import completed."
Rails.logger.debug "Linking character entries..."

# HskImporter already linked the cards it imported; only curated seed rows
# (and any strays) still need links. Re-linking everything would destroy and
# recreate every join row on each db:seed run.
Flashcard.where.missing(:flashcard_characters).find_each do |flashcard|
  CharacterLinker.call(flashcard)
end

Rails.logger.debug "Done."
