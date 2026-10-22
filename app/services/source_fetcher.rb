# Downloads a maintained source file when the task that needs one was
# not given a path. "Download the dictionary first" is a dev workflow:
# a production machine has no shared disk, so the fetch has to happen
# inside the run itself.
#
# The block receives the fetched file — or a plain file path, which is
# passed through unchanged — and the tempfile disappears after the
# block, so a run cannot leave the source bytes behind. Connection and
# HTTP-status failures raise with the URL so a console run says what it
# was actually trying to read.
require "faraday"

class SourceFetcher
  class FetchError < StandardError; end

  PINYIN_URL = "https://raw.githubusercontent.com/mozillazg/pinyin-data/master/pinyin.txt".freeze
  HSK_URL    = "https://raw.githubusercontent.com/drkameleon/complete-hsk-vocabulary/main/complete.json".freeze

  def self.open(path_or_url, connection: nil)
    return yield(path_or_url) unless url?(path_or_url)

    response = fetch(path_or_url, connection)
    tempfile = Tempfile.new("hanzitrail-source-", Rails.root.join("tmp").to_s)
    tempfile.write(response.body)
    # The block reads through its own file descriptor, which cannot see
    # bytes still parked in this handle's buffer.
    tempfile.flush

    begin
      yield tempfile.path
    ensure
      tempfile.close!
    end
  end

  def self.url?(value)
    value.start_with?("http://", "https://")
  end

  def self.fetch(url, connection)
    connection ||= Faraday.new do |faraday|
      faraday.options.open_timeout = 10
      faraday.options.timeout = 120
    end

    response =
      begin
        connection.get(url)
      rescue Faraday::Error => error
        raise FetchError, "download failed: #{url} (#{error.message})"
      end

    return response if response.status.between?(200, 299)

    raise FetchError, "download failed: #{url} (HTTP #{response.status})"
  end
  private_class_method :fetch
end
