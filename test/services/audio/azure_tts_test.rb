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

    # Regression: `f.request :raise_error` only fails when the production
    # connection builder runs — injected fakes in the retry tests never
    # execute it, and the failure shipped to the first prod validation run.
    # The connection builder reads credentials from ENV; the test env
    # intentionally has none, so stub them for its duration and restore.
    def with_azure_env
      keys = { "AZURE_SPEECH_KEY" => "test-key", "AZURE_SPEECH_REGION" => "testregion" }
      saved = keys.transform_values { |key| ENV[key] }
      keys.each { |key, value| ENV[key] = value }
      yield
    ensure
      keys.each do |key, value|
        saved[key] ? ENV[key] = saved[key] : ENV.delete(key)
      end
    end

    test "builds a real Faraday connection without middleware registry errors" do
      with_azure_env do
        tts = AzureTts.new

        # connection is private (internal detail) — the send is the point:
        # building it executes the middleware registry lookups.
        assert_instance_of Faraday::Connection, tts.send(:connection)
      end
    end

    test "connection honors the configured timeout" do
      with_azure_env do
        tts = AzureTts.new

        assert_equal AzureTts::TIMEOUT_SECONDS, tts.send(:connection).options.timeout
      end
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

      # Bad keys / bad SSML fail identically forever; they re-raise as
      # SynthesisError (with Azure's body) without any backoff.
      assert_raises(AzureTts::SynthesisError) { @tts.synthesize(ssml: "<speak/>") }
      assert_empty @slept
    end

    test "a rejected render surfaces Azure's error body, not just the status" do
      # 400 bodies name the exact SSML/header problem; a bare status line
      # would make every rejection undiagnosable.
      @tts = make_tts([proc do
        error = Faraday::BadRequestError.new("the server responded with status 400")
        error.define_singleton_method(:response_body) { "<ssml>Invalid ph value</ssml>" }
        raise error
      end])

      error = assert_raises(AzureTts::SynthesisError) { @tts.synthesize(ssml: "<speak/>") }

      assert_match(/Invalid ph value/, error.message)
    end
  end
end
