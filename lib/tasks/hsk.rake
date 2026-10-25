namespace :hsk do
  desc "Replace HSK 2.0 (old-*) flashcards with HSK 3.0 (new-1..new-5). " \
       "Review attempts attached to deleted cards are cascade-removed. " \
       "Idempotent: safe to re-run."
  task migrate_to_v3: :environment do
    # Deletion must precede import: HskImporter skips persisted characters,
    # so any old card left behind (e.g. 爱) would block its new-N replacement
    # and keep the stale old-1 tag.
    old = Flashcard.where(source: "hsk").where("hsk_level LIKE ?", "old-%")
    puts "Deleting #{old.count} HSK 2.0 cards (their review attempts go with them)..."
    old.destroy_all

    (1..5).each do |level|
      print "Importing new-#{level}... "
      HskImporter.import!(
        path: Rails.root.join("vendor/datasets/hsk/new/#{level}.json"),
        hsk_level: "new-#{level}"
      )
      puts "done"
    end

    puts format("HSK 3.0 migration complete: %d hsk cards, %d characters linked.",
                Flashcard.where(source: "hsk").count, CharacterEntry.count)
  end
end
