namespace :sessions do
  desc "Delete expired sign-in sessions (run periodically, e.g. via cron)"
  task purge: :environment do
    count = Session.expired.delete_all
    puts "Deleted #{count} expired session(s)."
  end
end
