require "test_helper"

class ApplicationJobTest < ActiveJob::TestCase
  test "defines a base job class" do
    assert_kind_of Class, ApplicationJob
    assert_operator ApplicationJob, :<, ActiveJob::Base
  end
end
