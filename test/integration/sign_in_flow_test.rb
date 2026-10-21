require "test_helper"

class SignInFlowTest < ActionDispatch::IntegrationTest
  test "bounces an anonymous editor through sign-in and back to the intended page" do
    flashcard = flashcards(:network)

    # A gated page asks for authentication and
    # remembers the path — not the full URL —
    # the visitor was headed for.
    get edit_flashcard_path(flashcard)

    assert_redirected_to new_session_path
    assert_equal edit_flashcard_path(flashcard), session[:return_to_after_authenticating]
    assert_equal "Sign in to edit content.", flash[:alert]

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Sign in to edit content."

    post session_path, params: {
      email_address: users(:one).email_address,
      password: "password"
    }

    # After signing in the visitor lands on the
    # intended page, not the site root and not
    # an absolute URL.
    assert_redirected_to edit_flashcard_path(flashcard)
    follow_redirect!
    assert_response :success
    assert_nil session[:return_to_after_authenticating]
  end

  test "signs in to the root when no return path is stored" do
    post session_path, params: {
      email_address: users(:one).email_address,
      password: "password"
    }

    assert_redirected_to root_path
    assert_nil session[:return_to_after_authenticating]
  end

  test "an expired session is treated as signed out" do
    # The cookie still holds a session id, but the
    # session's TTL has elapsed, so the gated page
    # must ask for authentication again.
    expired = users(:one).sessions.create!(expires_at: 1.hour.ago)
    set_session_cookie(expired)

    get edit_flashcard_path(flashcards(:network))

    assert_redirected_to new_session_path
  end

  test "resumes an active session from the cookie alone" do
    live = users(:one).sessions.create!(expires_at: Session::SESSION_TTL.from_now)
    set_session_cookie(live)

    get edit_flashcard_path(flashcards(:network))

    assert_response :success
  end

  private

  # Rack::Test's cookie jar cannot sign values, so write
  # the signed session id through a throwaway request's
  # cookie jar (same approach as SessionTestHelper).
  def set_session_cookie(session_record)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = session_record.id
      cookies["session_id"] = cookie_jar[:session_id]
    end
  end
end
