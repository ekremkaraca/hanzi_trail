# test/controllers/flashcards_controller_test.rb

require "test_helper"

class FlashcardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @flashcard = flashcards(:network)
  end

  test "should get index" do
    get flashcards_url
    assert_response :success
  end

  test "anonymous visitors are sent to sign-in for write actions" do
    get new_flashcard_url
    assert_redirected_to new_session_path

    get edit_flashcard_url(@flashcard)
    assert_redirected_to new_session_path

    assert_no_difference("Flashcard.count") do
      post flashcards_url, params: {
        flashcard: { character: "北京", pinyin: "Běijīng", meaning: "Beijing" }
      }
    end
    assert_redirected_to new_session_path

    patch flashcard_url(@flashcard), params: { flashcard: { meaning: "nope" } }
    assert_redirected_to new_session_path
    assert_not_equal "nope", @flashcard.reload.meaning

    assert_no_difference("Flashcard.count") do
      delete flashcard_url(@flashcard)
    end
    assert_redirected_to new_session_path
  end

  test "curators can get new" do
    sign_in_as users(:one)

    get new_flashcard_url
    assert_response :success
  end

  test "signed-in curator sees write affordances on public index" do
    sign_in_as users(:one)

    get flashcards_url
    assert_response :success
    assert_select "a[href=?]", new_flashcard_path, text: "New flashcard"
    assert_select "a[href=?]", new_session_path, count: 0
  end

  test "anonymous visitors see sign-in affordances on index" do
    get flashcards_url

    assert_select "a[href=?]", new_session_path, text: "Sign in to create"
    assert_select "a[href=?]", new_flashcard_path, count: 0
  end

  test "curators create flashcard" do
    sign_in_as users(:one)

    assert_difference("Flashcard.count", 1) do
      post flashcards_url, params: {
        flashcard: {
          character: "北京",
          pinyin: "Běijīng",
          meaning: "Beijing",
          story: "北 means north; 京 means capital.",
          category: "cities"
        }
      }
    end

    assert_redirected_to flashcard_url(Flashcard.find_by(character: "北京"))
  end

  test "curators can get edit" do
    sign_in_as users(:one)

    get edit_flashcard_url(@flashcard)
    assert_response :success
  end

  test "curators update flashcard" do
    sign_in_as users(:one)

    patch flashcard_url(@flashcard), params: {
      flashcard: { meaning: "network / web / mesh" }
    }

    assert_redirected_to flashcard_url(@flashcard)
    assert_equal "network / web / mesh", @flashcard.reload.meaning
  end

  test "curators destroy flashcard" do
    sign_in_as users(:one)

    assert_difference("Flashcard.count", -1) do
      delete flashcard_url(@flashcard)
    end

    assert_redirected_to flashcards_url
  end

  test "should show flashcard" do
    get flashcard_url(@flashcard)
    assert_response :success
  end

  test "index shows all flashcards by default" do
    get flashcards_path

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:network).character
    assert_select ".flashcard-character-link", text: flashcards(:algorithm).character
  end

  test "index filters by source" do
    get flashcards_path, params: { source: "hsk" }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
    assert_select ".flashcard-character-link", text: flashcards(:network).character, count: 0
  end

  test "index filters by hsk level" do
    get flashcards_path, params: { hsk_level: "old-1" }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
    assert_select ".flashcard-character-link", text: flashcards(:network).character, count: 0
  end

  test "index filters by category" do
    get flashcards_path, params: { category: "technical" }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:network).character
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character, count: 0
  end

  test "index shows clear filters link" do
    get flashcards_path, params: { source: "hsk" }

    assert_response :success
    assert_select "a[href=?]", flashcards_path, text: "Clear"
  end

  test "index all-empty filter query shows all flashcards" do
    get flashcards_path, params: {
      source: "",
      hsk_level: "",
      category: "",
      story_status: "",
      commit: "Filter"
    }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:network).character
    assert_select ".flashcard-character-link", text: flashcards(:algorithm).character
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
  end

  test "index filters by story status" do
    flashcards(:network).update!(story_status: "curated")
    flashcards(:hsk_one).update!(story_status: "missing")

    get flashcards_path, params: { story_status: "missing" }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
    assert_select ".flashcard-character-link", text: flashcards(:network).character, count: 0
  end

  test "index shows story status badge" do
    flashcards(:network).update!(story_status: "curated")

    get flashcards_path

    assert_response :success
    assert_includes response.body, "Curated Story"
  end

  test "index filters by search query" do
    get flashcards_path, params: { query: "network" }
    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:network).character
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character, count: 0
  end

  test "index combines search query and source filter" do
    flashcards(:network).update!(source: "curated")
    flashcards(:hsk_one).update!(source: "hsk", meaning: "network practice")

    get flashcards_path, params: {
      query: "network",
      source: "hsk"
    }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
    assert_select ".flashcard-character-link", text: flashcards(:network).character, count: 0
  end

  test "index shows missing stories shortcut" do
    get flashcards_path

    assert_response :success
    assert_select "a[href=?]", flashcards_path(story_status: "missing"), text: "Missing stories"
  end

  test "index filters by missing story status" do
    flashcards(:network).update!(story_status: "curated")
    flashcards(:hsk_one).update!(story_status: "missing")

    get flashcards_path, params: { story_status: "missing" }

    assert_response :success
    assert_select ".flashcard-character-link", text: flashcards(:hsk_one).character
    assert_select ".flashcard-character-link", text: flashcards(:network).character, count: 0
  end

  test "index shows empty state when filters match no flashcards" do
    get flashcards_path, params: { query: "nonexistent-query" }

    assert_response :success
    assert_includes response.body, "No flashcards matched your filter"
    assert_select "a[href=?]", flashcards_path, text: "Browse all flashcards"
  end

  test "index shows draft stories shortcut" do
    get flashcards_path

    assert_response :success
    assert_select "a[href=?]", flashcards_path(story_status: "draft"), text: "Draft stories"
  end

  test "index filters short stories" do
    short_story_card = flashcards(:network)
    long_story_card = flashcards(:algorithm)

    short_story_card.update!(
      story: "A network of connections."
    )

    long_story_card.update!(
      story: "This is a longer story that should not be considered short because it has enough explanatory detail."
    )

    get flashcards_path, params: { story_status: "short" }

    assert_response :success
    assert_select ".flashcard-character-link", text: short_story_card.character
    assert_select ".flashcard-character-link", text: long_story_card.character, count: 0
  end

  test "index shows empty state when no short stories exist" do
    flashcards(:network).update!(story: "A" * 81)
    flashcards(:algorithm).update!(story: "A" * 81)
    flashcards(:future_review).update!(story: "A" * 81)
    flashcards(:overdue_review).update!(story: "A" * 81)

    get flashcards_path, params: { story_status: "short" }

    assert_response :success
    assert_includes response.body, "No short stories found."
    assert_select "a[href=?]", flashcards_path, text: "Browse all flashcards"
  end

  test "shows recent review attempts" do
    get flashcard_path(flashcards(:network))

    assert_response :success
  end

  test "index applies search filter before limit" do
    3.times { |i| Flashcard.create!(character: "z#{i}", pinyin: "z", meaning: "z") }
    get flashcards_path, params: { query: "zzz_no_match_zzz" }
    assert_response :success
    assert_includes response.body, "No flashcards matched your filter"
  end

  test "index caps at 200 cards and orders deterministically" do
    220.times do |i|
      Flashcard.create!(
        character: "溢#{format("%03d", i)}",
        pinyin: "yì",
        meaning: "limitmarker",
        category: "limit_test",
        source: "curated"
      )
    end

    get flashcards_path, params: { category: "limit_test" }
    first_cards = response.body.scan(/flashcard-character-link" href="\/flashcards\/\d+">([^<]+)</).flatten

    assert_equal 200, first_cards.size
    assert_equal first_cards, first_cards.sort
    assert_equal "溢000", first_cards.first
    assert_equal "溢199", first_cards.last

    get flashcards_path, params: { category: "limit_test" }
    second_cards = response.body.scan(/flashcard-character-link" href="\/flashcards\/\d+">([^<]+)</).flatten

    assert_equal first_cards, second_cards
  end
end
