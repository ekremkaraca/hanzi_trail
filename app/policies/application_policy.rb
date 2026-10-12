# Base class for application policies.
class ApplicationPolicy < ActionPolicy::Base
  # Anonymous visitors are first-class here (public browse + practice),
  # so the user context must tolerate nil.
  authorize :user, allow_nil: true

  # Fail-closed default (ActionPolicy::Base's default_rule :manage?):
  # rules not defined in a policy require a signed-in curator. Note the
  # gem pre-defines index?/create? as false stubs, so those two must be
  # overridden explicitly wherever they matter. Roles (e.g. admin-only
  # destroy) slot in here later without touching controllers.
  #
  # Rule methods must stay public — no `private` section in policies.
  def manage?
    user.present?
  end
end
