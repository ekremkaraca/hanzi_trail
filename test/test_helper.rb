# Load and launch SimpleCov at the very top of your test helper
require "simplecov"

SimpleCov.merge_subprocesses true
# For forked child processes, SimpleCov's built-in at_fork block can't
# register a new at_exit hook because @at_exit_hook_installed is inherited
# from the parent. Register one manually so each child saves its results.
SimpleCov.at_fork do |pid|
  SimpleCov.command_name "Minitest_#{pid}"
  SimpleCov.print_errors false
  SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter
  SimpleCov.minimum_coverage 0
  SimpleCov.start
  Kernel.at_exit { Coverage.running? && SimpleCov.at_exit_behavior }
end
SimpleCov.start "rails"

# Previous content of test helper now starts here
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
# Enable component-level tests for UI now owned by ViewComponent classes.
require "view_component/test_case"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
