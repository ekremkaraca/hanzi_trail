require "test_helper"

module Audio
  class AzureTtsTest < ActiveSupport::TestCase
    # Scripted connection: raises (raise_error middleware semantics) or
    # returns per entry, then echoes the last entry forever.
    FakeResponse = Struct.new(:body)

    class FakeConnection
      def initialize(script)
        @script = script
      end

      def post(*)
        action = @script.shift
        case action
        when Symbol then raise action_const(action), action.to_s
        when Proc then action.call
        when String then FakeResponse.new(action)
        else FakeResponse.new("mp3-bytes")
        end
      end

      private

      def action_const(action)
        case action
        when :too_many_requests then Faraday::TooManyRequestsError.new("the response is 429")
        when :server_error then Faraday::ServerError.new("the response is 500")
        when :client_error then Faraday::ClientError.new("the response is 401")
        end
      end
    end

    setup do
      @slept = []
    end

    # Builds the service with a scripted connection and an instant,
    # recording backoff. Bare `sleep` resolves on the instance, so the
    # singleton stub intercepts the retry scheduler without patching
    # Kernel globally — and per-test construction keeps the stub attached.
    def make_tts(script)
      tts = AzureTts.new(connection: FakeConnection.new(script))
      slept = @slept
      tts.define_singleton_method(:sleep) { |seconds| slept << seconds }
      tts
    end

    test "returns the MP3 body on success" do
      @tts = make_tts(["mp3-ok"])

      assert_equal "mp3-ok", @tts.synthesize(ssml: "<speak/>")
    end

    test "retries 429s with exponential backoff, then succeeds" do
      @tts = make_tts([:too_many_requests, :too_many_requests, "mp3-ok"])

      assert_equal "mp3-ok", @tts.synthesize(ssml: "<speak/>")
      assert_equal [1, 2], @slept
    end

    test "retries 5xx the same way" do
      @tts = make_tts([:server_error, "mp3-ok"])

      assert_equal "mp3-ok", @tts.synthesize(ssml: "<speak/>")
      assert_equal [1], @slept
    end

    test "gives up with SynthesisError after MAX_ATTEMPTS 429s" do
      script = Array.new(AzureTts::MAX_ATTEMPTS, :too_many_requests)
      @tts = make_tts(script)

      assert_raises(AzureTts::SynthesisError) { @tts.synthesize(ssml: "<speak/>") }
      assert_equal AzureTts::MAX_ATTEMPTS - 1, @slept.size
    end

    test "a client error like 401 fails fast with zero retries" do
      @tts = make_tts([:client_error])

      # Bad keys / bad SSML fail identically forever; retrying them only
      # delays the failure report.
      assert_raises(Faraday::ClientError) { @tts.synthesize(ssml: "<speak/>") }
      assert_empty @slept
    end
  end
end
