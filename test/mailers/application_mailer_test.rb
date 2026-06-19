require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  test "defines default from" do
    assert_equal "from@example.com",
      ApplicationMailer.default[:from]
  end

  test "defines mailer layout" do
    assert_equal "mailer", ApplicationMailer._layout
  end
end
