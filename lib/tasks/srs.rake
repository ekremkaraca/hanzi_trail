namespace :srs do
  # One-off fix for the old import-time stagger: imported cards were
  # parked months into the future (new-3 was due Dec 2026-Jan 2027),
  # locking every HSK3 word out of review. Due-date pacing is now the
  # daily cap's job alone, so this pulls never-reviewed future cards
  # back to today.
  #
  # Safe by construction: only cards with review_count == 0 and a
  # FUTURE next_review_at are touched. Cards the SRS has scheduled
  # (review_count > 0) are never moved, and re-runs are no-ops once
  # everything unreviewed is due.
  desc "Pull never-reviewed future cards back to today (undoes the import stagger)"
  task :pull_forward, [:scope] => :environment do |_, args|
    parked = Flashcard.where(review_count: 0).where("next_review_at > ?", Time.current)
    parked = parked.where(hsk_level: args[:scope]) if args[:scope].present?

    puts "Pulling #{parked.count} parked cards forward to now (scope: #{args[:scope] || 'all'})"
    parked.find_each(batch_size: 500) { |card| card.update_columns(next_review_at: Time.current) }
    puts "Done. #{Flashcard.where(review_count: 0).where('next_review_at > ?', Time.current).count} parked cards remain."
  end
end
