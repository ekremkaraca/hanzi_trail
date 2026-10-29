require "test_helper"

module Audio
  class StorageTest < ActiveSupport::TestCase
    # Records the put_object call instead of touching a real client.
    class RecordingClient
      attr_reader :calls

      def initialize
        @calls = []
      end

      def put_object(args)
        @calls << args
        Struct.new(:etag).new('"abc"')
      end
    end

    # Storage env config is absent in tests; stub it for the duration.
    def with_storage_env
      saved = %w[R2_BUCKET R2_CDN_BASE R2_ENDPOINT R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY]
                .to_h { |k| [k, ENV[k]] }
      ENV["R2_BUCKET"] = "test-bucket"
      ENV["R2_CDN_BASE"] = "https://cdn.test"
      yield
    ensure
      saved.each { |k, v| v ? ENV[k] = v : ENV.delete(k) }
    end

    setup do
      @client = RecordingClient.new
      AudioStorage.client = @client
    end

    test "upload! puts immutable MP3 bytes under the bucket key" do
      with_storage_env do
        AudioStorage.upload!("words/12-xiaoxiao.mp3", "mp3-bytes")

        call = @client.calls.sole
        assert_equal "words/12-xiaoxiao.mp3", call[:key]
        assert_equal "mp3-bytes", call[:body]
        assert_equal "audio/mpeg", call[:content_type]
        assert_match(/immutable/, call[:cache_control])
        assert_equal "test-bucket", call[:bucket]
      end
    end

    test "public_url composes the CDN base with the key" do
      with_storage_env do
        assert_equal "https://cdn.test/words/12-xiaoxiao.mp3",
          AudioStorage.public_url("words/12-xiaoxiao.mp3")
      end
    end

    test "missing storage config fails loudly, naming the variable" do
      AudioStorage.client = nil
      with_storage_env do
        ENV.delete("R2_ENDPOINT")
        error = assert_raises(KeyError) { AudioStorage.client }
        assert_match(/R2_ENDPOINT/, error.message)
      end
    end
  end
end
