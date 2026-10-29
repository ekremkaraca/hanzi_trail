require "faraday"

module Audio
  # Thin Azure Speech wrapper for the per-call REST endpoint. Per-call is
  # deliberate for a one-off ~4k-card corpus: the batch API adds polling
  # state for no real win at this size (see the rake task).
  #
  # Retry drives off exceptions raised by the :raise_error middleware —
  # without it Faraday returns 429/5xx as plain responses and a rescue
  # block would never fire. The middleware also gives the fail-fast
  # asymmetry for free: 4xx other than 429 raises Faraday::ClientError,
  # which is deliberately NOT rescued (a bad key or bad SSML fails
  # identically forever).
  class AzureTts
    OUTPUT_FORMAT = "audio-24khz-48kbitrate-mono-mp3"
    # Small enough to retry within a task run, large enough to real backoff.
    MAX_ATTEMPTS = 4
    BACKOFF_SECONDS = 2
    TIMEOUT_SECONDS = 30

    class SynthesisError < StandardError; end

    def self.synthesize(ssml:)
      new.synthesize(ssml: ssml)
    end

    def initialize(connection: nil)
      # Injectable for tests; production builds one lazily on first use.
      @connection = connection
    end

    def synthesize(ssml:)
      attempts = 0
      begin
        attempts += 1
        # Content-Type per request: the batch API on the same connection
        # would need application/json instead.
        connection
          .post("/cognitiveservices/v1", ssml, "Content-Type" => "application/ssml+xml")
          .body # binary MP3 string, as SilenceGuard/File.binwrite expect
      rescue Faraday::TooManyRequestsError, Faraday::ServerError => e
        raise synthesis_failure(attempts, e) if attempts >= MAX_ATTEMPTS

        sleep(BACKOFF_SECONDS**(attempts - 1))
        retry
      rescue Faraday::ClientError => e
        # No retry, but never lose Azure's reason: 400 bodies name the
        # exact SSML/header problem, which is the only way to debug a
        # rejected render.
        raise synthesis_failure(attempts, e)
      end
    end

    private

    def synthesis_failure(attempts, error)
      body = error.response_body.to_s.slice(0, 500)
      SynthesisError.new(
        "Azure TTS failed after #{attempts} attempt(s): #{error.message} #{body}"
      )
    end

    def connection
      @connection ||= Faraday.new(url: base_url) do |f|
        f.headers["Ocp-Apim-Subscription-Key"] = ENV.fetch("AZURE_SPEECH_KEY")
        f.headers["X-Microsoft-OutputFormat"] = OUTPUT_FORMAT
        # raise_error is a RESPONSE middleware — requesting it on the
        # request side fails to resolve at connection build time, which
        # is exactly what the first prod validation run hit.
        f.response :raise_error
        # Net::HTTP had an explicit read timeout; Faraday's default is none,
        # and a hung connection would stall an overnight render forever.
        f.options.timeout = TIMEOUT_SECONDS
        f.options.open_timeout = TIMEOUT_SECONDS
      end
    end

    def base_url
      "https://#{ENV.fetch('AZURE_SPEECH_REGION')}.tts.speech.microsoft.com"
    end
  end
end
