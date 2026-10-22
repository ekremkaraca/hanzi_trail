namespace :character_entries do
  desc "Create character links for all flashcards"
  task link: :environment do
    Flashcard.find_each do |flashcard|
      CharacterLinker.call(flashcard)
    end

    puts "Linked characters for #{Flashcard.count} flashcards."
  end

  desc "Fill missing character-entry pinyin from a pinyin dictionary " \
       "(bin/rails character_entries:fill_pinyin[path/to/pinyin.txt]; " \
       "DRY_RUN=1 previews, FORCE=1 re-imports dictionary-sourced values)"
  task :fill_pinyin, [ :path ] => :environment do |_task, args|
    path = args[:path] or abort "usage: bin/rails character_entries:fill_pinyin[path/to/pinyin.txt]"

    report = CharacterEntries::PinyinImporter.import!(
      path: path,
      dry_run: ENV["DRY_RUN"] == "1",
      force: ENV["FORCE"] == "1"
    )

    puts report.summary
  end
end
