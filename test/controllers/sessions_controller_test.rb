require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  # Regression: an array-valued credential (?email_address[]=a) reached
  # authenticate_by and raised ArgumentError, 500ing the public sign-in form.
  test "create survives array-valued credentials" do
    post session_path, params: { email_address: [ "a" ], password: [ "b" ] }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create survives a NUL byte in credentials" do
    post session_path, params: { email_address: "#{@user.email_address}\u0000", password: "password" }

    assert_response :redirect
  end
end
