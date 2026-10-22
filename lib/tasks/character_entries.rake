namespace :character_entries do
  desc "Create character links for all flashcards"
  task link: :environment do
    Flashcard.find_each do |flashcard|
      CharacterLinker.call(flashcard)
    end

    puts "Linked characters for #{Flashcard.count} flashcards."
  end

  desc "Fill missing character-entry pinyin from the pinyin dictionary " \
       "(bin/rails character_entries:fill_pinyin[path/to/pinyin.txt]; " \
       "without a path the maintained dictionary is fetched, " \
       "DRY_RUN=1 previews, FORCE=1 re-imports dictionary-sourced values)"
  task :fill_pinyin, [ :path ] => :environment do |_task, args|
    file = args[:path] || SourceFetcher::PINYIN_URL

    SourceFetcher.open(file) do |dictionary|
      report = CharacterEntries::PinyinImporter.import!(
        path: dictionary,
        dry_run: ENV["DRY_RUN"] == "1",
        force: ENV["FORCE"] == "1"
      )

      puts "Dictionary: #{file}" + (args[:path].blank? ? " (fetched)" : "")
      puts report.summary
    end
  end
end
