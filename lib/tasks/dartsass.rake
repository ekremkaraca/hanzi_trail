Rake::Task["dartsass:watch"].clear if Rake::Task.task_defined?("dartsass:watch")

namespace :dartsass do
  desc "Watch and build your Dart Sass CSS on file changes (clean shutdown on SIGINT)"
  task watch: :environment do
    system(*Dartsass::Runner.dartsass_compile_command, "--watch")
  rescue Interrupt
    # Graceful shutdown on Ctrl+C
  end
end
