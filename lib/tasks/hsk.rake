namespace :hsk do
  desc "Re-derive pinyin and meaning for cards imported from an HSK file, " \
       "skipping any card a curator has edited " \
       "(bin/rails hsk:reimport[path/to/complete.json]; DRY_RUN=1 previews)"
  task :reimport, [ :path ] => :environment do |_task, args|
    path = args[:path] or abort "usage: bin/rails hsk:reimport[path/to/complete.json]"

    report = HskReimporter.call(path: path, dry_run: ENV["DRY_RUN"] == "1")

    puts "Repaired #{report.updated.size} card(s):"
    report.updated.each do |change|
      puts "  #{change.character}: #{change.pinyin_from} -> #{change.pinyin_to}"
      puts "      #{change.meaning_from} -> #{change.meaning_to}"
    end

    puts "Already correct: #{report.unchanged.size}"
    puts "Left alone (edited by a curator): #{report.edited.size}" \
         "#{report.edited.empty? ? "" : " - #{report.edited.join(", ")}"}"
    puts "Left alone (not in this file): #{report.missing.size}" \
         "#{report.missing.empty? ? "" : " - #{report.missing.join(", ")}"}"

    puts "(dry run - nothing written)" if ENV["DRY_RUN"] == "1"
  end
end
