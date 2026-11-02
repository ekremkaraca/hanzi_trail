class ReviewsController < ApplicationController
  allow_unauthenticated_access

  # Anonymous practice is the design, but review updates mutate shared
  # card state (difficulty, review_count, next_review_at) under a public
  # endpoint. When the deployment outgrows a trusted-visitor MVP, set
  # REQUIRE_AUTH_FOR_REVIEWS=1 and only signed-in users can move those
  # numbers; the queue, prefs, and reset stay anonymous because they
  # touch no shared state.
  #
  # ENV is read per request, not at class-load: tests flip it without
  # reloading the controller, and the flag takes effect on the next
  # request after a fly secret change (no rebuild).
  def self.writes_require_authentication?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("REQUIRE_AUTH_FOR_REVIEWS", nil))
  end

  # Runs before rate_limit: with the flag on, an anonymous flood is
  # bounced to sign-in (zero writes, zero limiter state) instead of
  # burning 60/min of budget on actions that will never execute.
  before_action :require_authentication,
                if: -> { self.class.writes_require_authentication? }, only: :update

  # preferences and reset only touch the caller's own session and need
  # no limit; update appends a ReviewAttempt row and moves the shared
  # scheduling state, so a scripted flood must cost something even with
  # the auth flag off. 60 per minute is far above human review pace and
  # still bounds how fast rows can be written.
  rate_limit to: 60, within: 1.minute, only: :update,
             with: -> { redirect_to review_path(filter_params), alert: "Too many reviews, please slow down." }

  # One session[:review_sessions] key is created per filter
  # combination ever reviewed. Left unbounded that hash grows
  # with every distinct filter visited and can outgrow the
  # ~4 KB session cookie, raising CookieOverflow. Keep only the
  # most recent counters; older filters simply restart at 0.
  REVIEW_SESSION_LIMIT = 20

  def show
    # Queue owns filter-aware card selection; the controller only exposes view data.
    @review_queue = Review::Queue.new(
      filters: filter_params,
      session: session
    )

    @flashcard = @review_queue.next_card
    # One join+entry read for the current card; the answer tabs' visibility
    # check and component list then render from memory instead of issuing
    # two EXISTS queries plus a two-query association load per page view.
    @flashcard&.preload_character_links!
    @remaining_due_count = @review_queue.remaining_count
    @empty_state_title = empty_state_title
    @reviewed_count = reviewed_count
    @review_filter_params = filter_params
    @total_review_count = @reviewed_count + @remaining_due_count
    @reviewed_today_count = ReviewAttempt.today.count

    # Preserve the active review URL for "back to review" links on card pages.
    # Built from filter_params only, so stray query keys can never leak into
    # the stored URL that ApplicationHelper#link_to_active_review_if_present
    # later renders.
    session[:review_return_to] = @flashcard.present? ? review_path(filter_params) : nil
  end

  def update
    rating = review_params[:rating]

    # Keep invalid input as a redirect instead of surfacing a 500 from the service.
    return redirect_to review_path, alert: "Invalid review rating." unless Flashcard::REVIEW_RATINGS.include?(rating)

    # Find through the queue scope so filtered review URLs cannot rate outside cards.
    flashcard = Review::Queue.new(filters: filter_params, session: session)
                             .scope
                             .find(QueryParam.scalar(params.expect(:flashcard_id)))

    # Scheduler owns the locked mutation and review-attempt side effect.
    Review::Scheduler.new(
      flashcard: flashcard,
      rating: rating
    ).call

    # Count only successful reviews in the current filter-specific session.
    increment_reviewed_count

    redirect_to review_path(filter_params), notice: "Review saved."
  rescue Flashcard::CardNotDueError
    redirect_to review_path(filter_params),
                alert: "This card is not due for review."
  rescue ActiveRecord::RecordNotFound
    redirect_to review_path(filter_params),
                alert: "That card is not in the current review filter."
  rescue ActiveRecord::RecordInvalid
    # The scheduler's update!/create! only writes
    # server-controlled fields, so this should be
    # unreachable — but a failed save inside the lock
    # must not surface as a 500 mid-review.
    redirect_to review_path(filter_params),
                alert: "Could not save the review. Try again."
  end

  def preferences
    session[:show_pinyin] = params[:show_pinyin] == "1"

    redirect_to review_path(filter_params)
  end

  # Restart the per-filter progress counter from the empty state. PATCH, not
  # a GET query flag, so prefetched or replayed page views never reset it.
  def reset
    reset_reviewed_count

    redirect_to review_path(filter_params)
  end

  private

  class << self
    # Counters are day-scoped: each entry stores {"c" => count, "d" =>
    # "YYYY-MM-DD"}. A counter written on an earlier local day reads as 0,
    # so "N reviewed" always describes today's session with the current
    # filters instead of accumulating across weeks. Legacy integer values
    # (pre-schema sessions) are treated as expired rather than crashing.
    # Pure class method so the shape rules are unit-testable without a request.
    def counter_value(raw, today)
      return 0 unless raw.is_a?(Hash) && raw["d"] == today

      raw["c"].to_i
    end
  end

  def review_params
    { rating: params.dig(:review, :rating) }
  end

  # Single source of truth for the three filter keys used in redirects and
  # session keys. Blank values are dropped so e.g. ?source= and an absent
  # source produce the same review_path URL.
  def filter_params
    Review::FilterParams.from(params)
  end

  def empty_state_title
    source = QueryParam.scalar(params[:source])
    story_status = QueryParam.scalar(params[:story_status])
    category = QueryParam.scalar(params[:category])

    return "No HSK cards are due right now." if source == "hsk"
    return "No curated cards are due right now." if source == "curated"
    return "No missing-story cards are due right now." if story_status == "missing"
    return "No #{category.to_s.humanize.downcase} cards are due right now." if category.present?

    "No cards due right now."
  end

  def review_session_key
    # Use the shared filter module so the session key is built from the
    # same three keys the helper and redirect use. Each part is URI-escaped
    # before joining: a filter value can itself contain "&" or "="
    # (?category=a%26source%3Db), which would otherwise produce the same key
    # as a genuinely different filter set ({source: "b", category: "a"}) and
    # collapse their progress counters.
    filter_params
      .sort
      .map { |k, v| "#{k}=#{Rack::Utils.escape(v)}" }
      .join("&")
      .presence || "all"
  end

  def reviewed_count
    self.class.counter_value(
      (session[:review_sessions] || {})[review_session_key],
      Date.current.to_s
    )
  end

  def increment_reviewed_count
    sessions = session[:review_sessions] ||= {}
    # Re-insert so the active filter counts as most recently used.
    sessions.delete(review_session_key)
    sessions[review_session_key] = { "c" => reviewed_count + 1, "d" => Date.current.to_s }
    # Bound the hash (see REVIEW_SESSION_LIMIT) so the session
    # cookie cannot overflow.
    session[:review_sessions] = sessions.last(REVIEW_SESSION_LIMIT).to_h if sessions.size > REVIEW_SESSION_LIMIT
  end

  def reset_reviewed_count
    session[:review_sessions] ||= {}
    session[:review_sessions][review_session_key] = { "c" => 0, "d" => Date.current.to_s }
  end
end
