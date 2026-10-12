class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  # Keep the generated return-to bounce, but tell visitors why they landed
  # on the sign-in page.
  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path, alert: "Sign in to edit content."
  end

  def current_user
    Current.user
  end
  helper_method :current_user
end
