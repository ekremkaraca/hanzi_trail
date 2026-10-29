# Object storage for pre-rendered card audio (Cloudflare R2, S3-compatible).
#
# Keys are stored in flashcards.audio_key and public URLs are composed at
# read time from CDN_BASE — env-dependent values never get baked into
# 4k DB rows, so re-pointing at a new CDN is an env change, not a migration.
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
  end

  def self.public_url(key)
    "#{ENV.fetch('CDN_BASE')}/#{key}"
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
