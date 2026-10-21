module Authentication
  extend ActiveSupport::Concern

  included do
    # Always resume the session so public pages still know who is signed
    # in (navbar state, allowed_to? affordances). allow_unauthenticated_access
    # below skips only the enforcement, never the resume.
    before_action :resume_session
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      # Expired sessions stay invisible even while their
      # cookie still holds the id; the purge task deletes
      # the rows.
      return unless cookies.signed[:session_id]

      Session.active.find_by(id: cookies.signed[:session_id])
    end

    def request_authentication
      # Store only the path, not the full URL, so a spoofed Host
      # header can never turn this into an open redirect (host is
      # pinned in prod anyway). This is the only definition of the
      # method: a former ApplicationController override duplicated
      # it with request.url, silently reintroducing the full-URL
      # storage that the path-only version was written to remove.
      session[:return_to_after_authenticating] = request.fullpath
      redirect_to new_session_path, alert: "Sign in to edit content."
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      # The cookie expires with the session's server-side
      # TTL so the browser drops it at the same time the
      # row becomes inert (not the 20-year permanent default).
      expires_at = Session::SESSION_TTL.from_now

      user.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip,
        expires_at: expires_at
      ).tap do |session|
        Current.session = session
        cookies.signed[:session_id] = {
          value: session.id,
          expires: expires_at,
          httponly: true,
          same_site: :lax
        }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
