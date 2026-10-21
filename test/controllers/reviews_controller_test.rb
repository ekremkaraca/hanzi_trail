# test/controllers/reviews_controller_test.rb

require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Flashcard.update_all(next_review_at: 1.day.from_now)

    @flashcard = flashcards(:network)
    @flashcard.update!(next_review_at: 1.minute.ago)
  end

  test "should show review page" do
    get review_url

    assert_response :success
    assert_select "h1", "Review"
    assert_includes response.body, @flashcard.character
  end

  test "show filters by source" do
    flashcards(:hsk_one).update!(next_review_at: 1.minute.ago)

    get review_url(source: "hsk")

    assert_response :success
    assert_includes response.body, flashcards(:hsk_one).character
    assert_select ".review-character", text: @flashcard.character, count: 0
  end

  test "show filters by category" do
    flashcards(:algorithm).update!(next_review_at: 1.minute.ago)

    get review_url(category: "technical")

    assert_response :success
    assert_includes response.body, @flashcard.character
    assert_select ".review-character", text: flashcards(:hsk_one).character, count: 0
  end

  test "should update flashcard review state" do
    @flashcard.update!(source: "hsk")

    assert_difference -> { @flashcard.reload.review_count }, 1 do
      patch review_flashcard_url(@flashcard), params: {
        review: { rating: "good" },
        source: "hsk",
        category: "technical"
      }
    end

    assert_redirected_to review_url(source: "hsk", category: "technical")
    assert_equal "good", @flashcard.reload.difficulty
    assert_operator @flashcard.next_review_at, :>, Time.current
  end

  test "should redirect on invalid rating" do
    patch review_flashcard_url(@flashcard), params: {
      review: { rating: "invalid" }
    }

    assert_redirected_to review_url
  end

  test "should redirect when review param is missing" do
    patch review_flashcard_url(@flashcard)

    assert_redirected_to review_url
  end
  test "show displays remaining due count" do
    flashcards(:network).update!(next_review_at: 1.minute.ago)
    flashcards(:hsk_one).update!(next_review_at: 2.minutes.ago)

    get review_url

    assert_response :success
    assert_includes response.body, "Cards remaining: 2"
  end
  test "show displays shortcut hints" do
    flashcards(:network).update!(next_review_at: 1.minute.ago)

    get review_url

    assert_response :success
    assert_includes response.body, "Again · 1"
    assert_includes response.body, "Hard · 2"
    assert_includes response.body, "Good · 3"
    assert_includes response.body, "Easy · 4"
  end

  test "show wires keyboard shortcut handler" do
    get review_url

    assert_response :success
    assert_includes response.body, "keydown@window->review#handleKeydown"
    assert_includes response.body, "review:toggle"
  end

  test "show wires speak button to review character" do
    get review_url

    assert_response :success
    assert_includes response.body, "data-review-target=\"character\""
    assert_includes response.body, "data-action=\"click->review#speak\""
  end

  test "show renders review buttons that submit ratings to due card" do
    flashcards(:network).update!(next_review_at: 1.minute.ago)

    get review_url

    assert_response :success
    assert_select "form[action=?][method=post]", review_flashcard_path(flashcards(:network)) do
      assert_select "input[name=_method][value=patch]", 4
      assert_select "input[name='review[rating]'][value=again]", 1
      assert_select "input[name='review[rating]'][value=hard]", 1
      assert_select "input[name='review[rating]'][value=good]", 1
      assert_select "input[name='review[rating]'][value=easy]", 1
    end
  end

  test "show displays empty state when no cards are due" do
    Flashcard.update_all(next_review_at: 1.day.from_now)

    get review_url

    assert_response :success
    assert_includes response.body, "No cards due right now"
    assert_select "a[href=?]", flashcards_path, text: "Browse flashcards"
  end

  test "show displays empty state for hsk queue when no hsk cards are due" do
    get review_url(source: "hsk")

    assert_response :success
    assert_includes response.body, "No HSK cards are due right now"
  end

  test "show displays empty state for technical queue when no technical cards are due" do
    Flashcard.where(category: "technical").update_all(next_review_at: 1.day.from_now)

    get review_url(category: "technical")

    assert_response :success
    assert_includes response.body, "No technical cards are due right now"
  end

  test "show displays review progress" do
    flashcards(:network).update!(next_review_at: 1.minute.ago)

    get review_path

    assert_response :success
    assert_includes response.body, "0 reviewed"
    assert_includes response.body, "1 remaining"
  end

  test "review update increments reviewed count" do
    flashcard = flashcards(:network)
    flashcard.update!(next_review_at: 1.minute.ago)
    flashcards(:algorithm).update!(next_review_at: 1.minute.ago)

    patch review_flashcard_path(flashcard),
      params: { review: { rating: "good" } }

    follow_redirect!

    assert_response :success
    assert_includes response.body, "1 reviewed"
  end

  test "reviewed count is separated by review filters" do
    hsk_card = flashcards(:hsk_one)
    curated_card = flashcards(:network)

    hsk_card.update!(source: "hsk", next_review_at: 1.minute.ago)
    flashcards(:hsk_two).update!(source: "hsk", next_review_at: 1.minute.ago)
    curated_card.update!(source: "curated", next_review_at: 1.minute.ago)

    patch review_flashcard_path(hsk_card, source: "hsk"),
      params: { review: { rating: "good" } }

    get review_path(source: "hsk")
    assert_includes response.body, "1 reviewed"

    get review_path(source: "curated")
    assert_includes response.body, "0 reviewed"
  end

  test "show displays completion state after reviewing final card" do
    flashcard = flashcards(:network)
    flashcard.update!(next_review_at: 1.minute.ago)

    patch review_flashcard_path(flashcard),
      params: { review: { rating: "good" } }

    follow_redirect!

    assert_response :success
    assert_includes response.body, "Review session complete"
    assert_includes response.body, "You reviewed 1 card"
  end

  test "reviewed count does not collide between source and category with same value" do
    hsk_card = flashcards(:hsk_one)
    hsk_card.update!(next_review_at: 1.minute.ago)
    flashcards(:hsk_two).update!(next_review_at: 1.minute.ago)
    flashcards(:overdue_review).update!(category: "hsk", next_review_at: 1.minute.ago)

    patch review_flashcard_path(hsk_card, source: "hsk"),
      params: { review: { rating: "good" } }

    get review_path(source: "hsk")
    assert_includes response.body, "1 reviewed"

    get review_path(category: "hsk")
    assert_includes response.body, "0 reviewed"
  end

  test "reviewed count does not collide between source and story_status with same value" do
    card = flashcards(:hsk_one)
    card.update!(next_review_at: 1.minute.ago, source: "curated", story_status: "curated")
    flashcards(:hsk_two).update!(next_review_at: 1.minute.ago, source: "curated", story_status: "curated")

    patch review_flashcard_path(card, source: "curated"),
      params: { review: { rating: "good" } }

    get review_path(source: "curated")
    assert_includes response.body, "1 reviewed"

    get review_path(story_status: "curated")
    assert_includes response.body, "0 reviewed"
  end

  test "reviewed count does not collide between category and story_status with same value" do
    card = flashcards(:network)
    card.update!(next_review_at: 1.minute.ago, category: "missing")
    flashcards(:algorithm).update!(next_review_at: 1.minute.ago, category: "missing")

    patch review_flashcard_path(card, category: "missing"),
      params: { review: { rating: "good" } }

    get review_path(category: "missing")
    assert_includes response.body, "1 reviewed"

    get review_path(story_status: "missing")
    assert_includes response.body, "0 reviewed"
  end

  test "reviewed count does not collide when multi-param combination differs from single param" do
    combined_card = flashcards(:network)
    combined_card.update!(
      next_review_at: 1.minute.ago,
      source: "curated",
      category: "hsk"
    )
    flashcards(:algorithm).update!(
      next_review_at: 1.minute.ago,
      source: "curated",
      category: "hsk"
    )

    patch review_flashcard_path(combined_card, source: "curated", category: "hsk"),
      params: { review: { rating: "good" } }

    get review_path(source: "curated", category: "hsk")
    assert_includes response.body, "1 reviewed"

    get review_path(source: "curated")
    assert_includes response.body, "0 reviewed"
  end

  test "blank parameter values share the unfiltered session" do
    card = flashcards(:network)
    card.update!(next_review_at: 1.minute.ago)
    flashcards(:algorithm).update!(next_review_at: 1.minute.ago)

    patch review_flashcard_path(card),
      params: { review: { rating: "good" } }

    get review_path
    assert_includes response.body, "1 reviewed"

    get review_path(source: "")
    assert_includes response.body, "1 reviewed"

    get review_path(category: "")
    assert_includes response.body, "1 reviewed"

    get review_path(source: "", category: "", story_status: "")
    assert_includes response.body, "1 reviewed"
  end

  test "all three filter params produce distinct session keys from each other" do
    card = flashcards(:network)
    card.update!(
      next_review_at: 1.minute.ago,
      source: "curated",
      category: "curated",
      story_status: "curated"
    )
    flashcards(:algorithm).update!(
      next_review_at: 1.minute.ago,
      source: "curated",
      category: "curated",
      story_status: "curated"
    )
    flashcards(:overdue_review).update!(
      next_review_at: 1.minute.ago,
      story_status: "curated"
    )

    patch review_flashcard_path(card, source: "curated"),
      params: { review: { rating: "good" } }

    get review_path(source: "curated")
    assert_includes response.body, "1 reviewed"

    get review_path(category: "curated")
    assert_includes response.body, "0 reviewed"

    get review_path(story_status: "curated")
    assert_includes response.body, "0 reviewed"
  end

  test "show displays review progress text" do
    flashcards(:network).update!(next_review_at: 1.minute.ago)

    get review_path

    assert_response :success
    assert_includes response.body, "0 reviewed"
    assert_includes response.body, "1 remaining"
  end

  test "rejects rating for card with next_review_at in the future" do
    future_card = flashcards(:future_review)

    assert_no_difference -> { future_card.reload.review_count } do
      patch review_flashcard_url(future_card), params: {
        review: { rating: "good" }
      }
    end

    assert_redirected_to review_path
    assert_equal "This card is not due for review.", flash[:alert]
    assert future_card.reload.next_review_at > Time.current
    assert_equal "new", future_card.reload.difficulty
  end

  test "rejects rating when card is outside the current filter scope" do
    curated_card = flashcards(:network)
    curated_card.update!(next_review_at: 1.minute.ago)

    patch review_flashcard_url(curated_card, source: "hsk"),
      params: { review: { rating: "good" } }

    assert_redirected_to review_path(source: "hsk")
    assert_equal "That card is not in the current review filter.", flash[:alert]
  end

  test "redirects with an alert when saving the review fails validation" do
    flashcard = flashcards(:network)
    flashcard.update!(next_review_at: 1.minute.ago)

    # Simulate the scheduler's update!/create! raising
    # RecordInvalid inside its lock (Minitest 6 dropped
    # Object#stub, so swap call and restore afterwards).
    call = Review::Scheduler.instance_method(:call)
    Review::Scheduler.define_method(:call) do
      raise ActiveRecord::RecordInvalid.new(Flashcard.new)
    end

    begin
      patch review_flashcard_path(flashcard),
        params: { review: { rating: "good" } }

      assert_redirected_to review_path
      assert_equal "Could not save the review. Try again.", flash[:alert]
    ensure
      Review::Scheduler.define_method(:call, call)
    end
  end

  test "reset route restarts the reviewed counter" do
    flashcard = flashcards(:network)
    flashcard.update!(next_review_at: 1.minute.ago)
    flashcards(:algorithm).update!(next_review_at: 1.minute.ago)

    patch review_flashcard_path(flashcard),
      params: { review: { rating: "good" } }

    follow_redirect!
    assert_includes response.body, "1 reviewed"

    patch review_reset_path
    follow_redirect!
    assert_includes response.body, "0 reviewed"
  end

  test "reset route preserves the active filter" do
    patch review_reset_path(source: "hsk")

    assert_redirected_to review_path(source: "hsk")
  end

  test "return-to-review session path excludes transient query params" do
    flashcards(:hsk_one).update!(next_review_at: 1.minute.ago)

    get review_path(source: "hsk", some_junk: "1")

    assert_equal review_path(source: "hsk"), session[:review_return_to]
  end

  test "saving preferences preserves filters" do
    patch review_preferences_path, params: {
      show_pinyin: "1",
      source: "hsk",
      story_status: "missing"
    }

    assert_redirected_to(
      review_path(
        source: "hsk",
        story_status: "missing"
      )
    )
  end

  test "review supports short story filter" do
    get review_path(story_status: "short")

    assert_response :success
  end

  test "review page includes explore link for current card" do
    get review_path

    assert_response :success
    assert_select "a[href=?]", flashcard_path(assigns(:flashcard)), text: "Explore card"
  end

  test "shows completion state after reviewing all due cards" do
    flashcard = flashcards(:network)
    flashcard.update!(next_review_at: 1.minute.ago)

    patch review_flashcard_path(flashcard),
      params: { review: { rating: "good" } }

    follow_redirect!

    assert_response :success
    assert_select ".review-empty-state"
  end

  # Regression: a raw non-String filter value (?source[]=x) or a NUL byte
  # (?source=%00) reached a String-only scope and 500ed the public review page.
  test "review page survives a NUL byte in every filter" do
    %i[source category].each do |key|
      get review_path(key => "a\u0000b")
      assert_response :success, "?#{key} with a NUL byte should render, got #{response.status}"
    end
  end

  test "review page treats a nested-hash filter as absent instead of 500ing" do
    # A hash reaches a String-only comparison (?source[a]=b); the array shape is
    # tolerated by `where`, the hash is not.
    get review_path(source: { "a" => "b" })

    assert_response :success
  end

  # Regression: the session key joined raw values with "&"/"=", so a category
  # value containing them produced the same key as a genuinely different filter
  # set and the two filters shared one progress counter.
  test "filters whose values contain & or = do not share a session key" do
    crafted = flashcards(:network)
    crafted.update!(next_review_at: 1.minute.ago, category: "a&source=hsk", source: "hsk")
    plain = flashcards(:algorithm)
    plain.update!(next_review_at: 1.minute.ago, source: "hsk", category: "a")

    patch review_flashcard_path(crafted, category: "a&source=hsk"),
      params: { review: { rating: "good" } }
    assert_equal 1, session[:review_sessions].size

    patch review_flashcard_path(plain, source: "hsk", category: "a"),
      params: { review: { rating: "good" } }

    assert_equal 2, session[:review_sessions].size,
      "the crafted category collided with the {source: hsk, category: a} key"
  end
end
