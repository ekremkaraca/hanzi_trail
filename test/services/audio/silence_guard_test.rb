require "test_helper"

module Audio
  class SilenceGuardTest < ActiveSupport::TestCase
    test "accepts a realistic word-length MP3" do
      assert SilenceGuard.valid?("x" * 25_000)
    end

    test "rejects empty, tiny, and nil payloads" do
      # A broken play button is worse than no audio at all.
      assert_not SilenceGuard.valid?("")
      assert_not SilenceGuard.valid?("x" * 1_999)
      assert_not SilenceGuard.valid?(nil)
    end
  end
end
