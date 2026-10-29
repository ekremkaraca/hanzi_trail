module Audio
  # Quality gate: a 0-byte or near-silent MP3 stored as audio is WORSE than
  # no audio (the user taps play, nothing happens, they think the app is
  # broken). Reject anything under a size floor.
  class SilenceGuard
    # ~25KB is typical for a 1-2s word at 48kbps. Under 2KB means Azure
    # returned an error payload, silence, or a truncated file.
    MIN_BYTES = 2_000

    def self.valid?(mp3_bytes)
      mp3_bytes.to_s.bytesize >= MIN_BYTES
    end
  end
end
