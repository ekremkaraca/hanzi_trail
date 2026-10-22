require "test_helper"

class SourceFetcherTest < ActiveSupport::TestCase
  URL = "https://example.com/sources/pinyin.txt"

  # Duck-typed to what Faraday returns, since an injected connection is
  # how these tests stay offline.
  FakeResponse = Struct.new(:status, :body)

  class FakeConnection
    attr_reader :requested_urls

    def initialize(response)
      @response = response
      @requested_urls = []
    end

    def get(url)
      @requested_urls << url
      @response
    end
  end

  test "fetches a URL and hands the downloaded file to the block" do
    connection = FakeConnection.new(FakeResponse.new(200, "U+4E00: yī  # 一\n"))

    contents = SourceFetcher.open(URL, connection: connection) { |path| File.read(path) }

    assert_equal "U+4E00: yī  # 一\n", contents
    assert_equal [ URL ], connection.requested_urls
  end

  test "the fetched file is temporary and gone after the run" do
    connection = FakeConnection.new(FakeResponse.new(200, "data"))
    fetched_path = nil
    ran = false

    SourceFetcher.open(URL, connection: connection) do |path|
      fetched_path = path
      ran = true
      assert File.exist?(path)
    end

    assert ran
    refute File.exist?(fetched_path)
  end

  test "a plain file path is handed through and no fetch is made" do
    local = "/somewhere/pinyin.txt"

    passed = SourceFetcher.open(local) { |path| path }

    assert_equal local, passed
  end

  test "a non-success status raises naming the url" do
    connection = FakeConnection.new(FakeResponse.new(503, ""))

    error = assert_raises(SourceFetcher::FetchError) do
      SourceFetcher.open(URL, connection: connection) { |path| path }
    end

    assert_match(%r{download failed: https://example.com/sources/pinyin.txt \(HTTP 503\)}, error.message)
  end

  test "a connection failure raises naming the url" do
    connection = Class.new do
      def get(_url)
        raise Faraday::ConnectionFailed, "the network is down"
      end
    end.new

    error = assert_raises(SourceFetcher::FetchError) do
      SourceFetcher.open(URL, connection: connection) { |path| path }
    end

    assert_match(/the network is down/, error.message)
    assert_match(%r{https://example.com/sources/pinyin.txt}, error.message)
  end
end
