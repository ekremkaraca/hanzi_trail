# Storage for pre-rendered card audio, backed by the production Postgres.
#
# Postgres won over object storage (R2/S3) for the MVP: ~10MB for the
# 952 HSK3 words (~47MB for the full deck), no new provider, no extra
# secrets, and the render task needs nothing but DATABASE_URL + the
# Azure keys. The R2 sketch lives in git history if traffic ever
# justifies a CDN — the swap point is this module plus the audio_url
# helper; flashcards.audio_key stays the stable identifier either way.
module AudioStorage
  def self.upload!(flashcard, key, mp3_bytes)
    CardAudio.upsert_with_key!(flashcard, key, mp3_bytes)
  end

  def self.find_bytes(key)
    CardAudio.find_by!(key: key).bytes
  end

  def self.public_url(key)
    # Keys contain slashes ("words/12-xiaoxiao.mp3") — keep them whole.
    "/audios/#{key}"
  end
end
