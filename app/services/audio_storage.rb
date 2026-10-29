# Object storage for pre-rendered card audio (Cloudflare R2, S3-compatible).
#
# Postgres was tried first and reverted: Neon's free tier can't spare the
# ~10-47MB of blobs. Keys are stored in flashcards.audio_key and public
# URLs are composed at read time from R2_CDN_BASE — env-dependent values
# never get baked into 4k DB rows, so re-pointing at a new CDN is an env
# change, not a migration. The gem is require: false in the Gemfile, so
# the explicit require below is load-bearing (its absence was the
# "uninitialized constant Aws" prod crash).
require "aws-sdk-s3"

module AudioStorage
  def self.upload!(key, mp3_bytes)
    client.put_object(
      bucket: ENV.fetch("R2_BUCKET"),
      key: key,
      body: mp3_bytes,
      content_type: "audio/mpeg",
      # Objects are immutable per key (the key encodes card + voice), so
      # caches can hold them effectively forever.
      cache_control: "public, max-age=31536000, immutable"
    )
    key
  end

  def self.public_url(key)
    "#{ENV.fetch('R2_CDN_BASE')}/#{key}"
  end

  # Injectable for tests (a real client would need live credentials).
  def self.client=(replacement)
    @client = replacement
  end

  def self.client
    @client ||= Aws::S3::Client.new(
      endpoint: ENV.fetch("R2_ENDPOINT"),
      region: "auto",
      credentials: Aws::Credentials.new(
        ENV.fetch("R2_ACCESS_KEY_ID"),
        ENV.fetch("R2_SECRET_ACCESS_KEY")
      )
    )
  end
end
