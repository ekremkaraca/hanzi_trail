namespace :flashcards do
  desc "Report card pinyin that disagrees with a pinyin dictionary " \
       "(bin/rails flashcards:audit_pinyin[path/to/pinyin.txt]; " \
       "FIX_SPACING=1 separates unspaced syllables, DRY_RUN=1 previews)"
  task :audit_pinyin, [ :path ] => :environment do |_task, args|
    path = args[:path] or abort "usage: bin/rails flashcards:audit_pinyin[path/to/pinyin.txt]"

    report = CardPinyinAudit.call(
      path: path,
      fix_spacing: ENV["FIX_SPACING"] == "1",
      dry_run: ENV["DRY_RUN"] == "1"
    )

    puts "Checked #{report.checked} cards, #{report.findings.size} finding(s)"

    report.findings.group_by(&:kind).each do |kind, findings|
      puts "#{kind} (#{findings.size}):"
      findings.each do |finding|
        puts "  #{finding.character} #{finding.pinyin}: #{finding.detail}"
      end
    end

    puts "Re-spaced #{report.respaced.size} card(s):"
    report.respaced.each do |change|
      puts "  #{change.character}: #{change.from} -> #{change.to}"
    end

    puts "(dry run - nothing written)" if ENV["DRY_RUN"] == "1"
  end
end
