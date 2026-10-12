namespace :users do
  desc "Create a curator account: bin/rails users:create[you@example.com] " \
       "(password from USERS_PASSWORD env var or an interactive prompt)"
  task :create, [ :email_address ] => :environment do |_task, args|
    email = args[:email_address] or abort "usage: bin/rails users:create[email@example.com]"

    password = ENV["USERS_PASSWORD"] || begin
      require "io/console"
      print "Password (min 10 chars): "
      STDIN.noecho(&:gets).to_s.strip.tap { puts }
    end

    user = User.new(email_address: email, password: password)

    if user.save
      puts "Created curator account #{user.email_address}"
    else
      abort user.errors.full_messages.join(", ")
    end
  end
end
