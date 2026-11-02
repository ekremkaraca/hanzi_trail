# Regression test for the crash-loop this file's bare `daily` caused in
# production. solid_queue validates recurring schedules when the process
# boots (SolidQueue::RecurringTask#ensure_schedule_supported), and with
# SOLID_QUEUE_IN_PUMA set that validation runs inside the web process: an
# unsupported schedule logs "Invalid recurring tasks", exits, and Fly
# restarts the machine into a loop - health checks flap and every request
# pays a cold boot. Nothing in the suite covered it, so the config shipped.
#
# The rule is exact: Fugit.parse must return a Fugit::Cron. "daily" parses
# to nil; "every day" and "every day at 3am" parse to a Cron. Asserting
# through solid_queue's own model would need the queue database, so this
# pins the same predicate against the real config file instead.
require "test_helper"
require "fugit"

class RecurringScheduleTest < ActiveSupport::TestCase
  TASKS = begin
    all = ERB.new(Rails.root.join("config/recurring.yml").read).result
    (YAML.load(all) || {}).transform_keys(&:to_s)
  end

  # Every environment block, not just production: a schedule added under
  # any key should be valid before it can be deployed.
  def each_task
    TASKS.each do |env, tasks|
      (tasks || {}).each { |key, task| yield env, key.to_s, task }
    end
  end

  test "every recurring schedule parses to a Fugit cron" do
    seen = 0

    each_task do |env, key, task|
      seen += 1
      schedule = task["schedule"] || task[:schedule]

      assert schedule.present?, "#{env}/#{key} has no schedule"

      parsed = Fugit.parse(schedule.to_s, multi: :fail)

      assert_kind_of Fugit::Cron, parsed,
                     "#{env}/#{key}: schedule #{schedule.inspect} is not a supported " \
                     "recurring schedule (solid_queue rejects it and the booting " \
                     "process exits). Use an explicit cron or \"every day at 3am\" " \
                     "phrasing; bare \"daily\" parses to nil."
    end

    # Guards the guard: a silently empty config would pass vacuously.
    assert_operator seen, :>=, 2, "expected both recurring tasks to be read"
  end

  test "each task declares a command or a class" do
    # The other validate-on-boot rule (ensure_command_or_class_present).
    each_task do |env, key, task|
      command = task["command"] || task[:command]
      klass = task["class"] || task[:class]

      assert command.present? || klass.present?,
             "#{env}/#{key} has neither command nor class"
    end
  end

  test "the rejected phrasing stays rejected so this test cannot rot" do
    # `daily` is the value that shipped and crashed prod; if fugit ever
    # starts accepting it the assertion above becomes weaker silently.
    assert_nil Fugit.parse("daily", multi: :fail)
    assert_kind_of Fugit::Cron, Fugit.parse("every day at 3am", multi: :fail)
  end
end
