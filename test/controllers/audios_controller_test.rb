require "test_helper"

class AudiosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @card = flashcards(:network)
    AudioStorage.upload!(@card, "words/#{@card.id}-xiaoxiao.mp3", "fake-mp3-bytes")
  end

  test "serves stored audio to anonymous visitors with immutable caching" do
    get "/audios/words/#{@card.id}-xiaoxiao.mp3"

    assert_response :ok
    assert_equal "fake-mp3-bytes", response.body
    assert_equal "audio/mpeg", response.headers["Content-Type"]&.split(";")&.first
    assert_match(/immutable/, response.headers["Cache-Control"])
  end

  test "unknown keys are 404, not 500" do
    get "/audios/words/missing.mp3"

    assert_response :not_found
  end
end
