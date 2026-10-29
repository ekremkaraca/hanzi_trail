require "test_helper"

module Audio
  class StorageTest < ActiveSupport::TestCase
    test "upload! stores bytes under the key and is idempotent per key" do
      card = flashcards(:network)

      AudioStorage.upload!(card, "words/#{card.id}-xiaoxiao.mp3", "mp3-bytes-v1")
      AudioStorage.upload!(card, "words/#{card.id}-xiaoxiao.mp3", "mp3-bytes-v2")

      # Same key = same object, re-rendered in place, never duplicated.
      audio = CardAudio.find_by(key: "words/#{card.id}-xiaoxiao.mp3")
      assert_equal "mp3-bytes-v2", audio.bytes
      assert_equal card.id, audio.flashcard_id
      assert_equal 1, CardAudio.where(flashcard: card).count
    end

    test "find_bytes raises RecordNotFound for unknown keys" do
      assert_raises(ActiveRecord::RecordNotFound) { AudioStorage.find_bytes("words/missing.mp3") }
    end

    test "public_url maps a key to its serving route" do
      assert_equal "/audios/words/12-xiaoxiao.mp3", AudioStorage.public_url("words/12-xiaoxiao.mp3")
    end
  end
end
