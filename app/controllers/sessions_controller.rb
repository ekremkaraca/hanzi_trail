class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    # QueryParam.scalar keeps an Array/Hash credential (?email_address[]=a) from
    # reaching authenticate_by, which raised ArgumentError and 500ed the public
    # sign-in form; a non-String shape is treated as an absent credential.
    credentials = {
      email_address: QueryParam.scalar(params[:email_address]),
      password: QueryParam.scalar(params[:password])
    }

    if user = User.authenticate_by(credentials)
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
