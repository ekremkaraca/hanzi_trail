namespace :sessions do
  desc "Delete expired sign-in sessions (also run daily by the recurring task in config/recurring.yml)"
  task purge: :environment do
    count = Session.expired.delete_all
    puts "Deleted #{count} expired session(s)."
  end
end
