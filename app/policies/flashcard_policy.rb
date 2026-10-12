class FlashcardPolicy < ApplicationPolicy
  # Public surface, stated explicitly so this file doubles as the guest
  # contract. (ActionPolicy's Defaults pre-defines index?/create? as
  # false stubs, so they must be overridden rather than left to resolve.)
  def index?
    true
  end

  def show?
    true
  end

  def create?
    manage?
  end

  # new? (aliased to create? by default) plus edit?/update?/destroy?
  # resolve to ApplicationPolicy#manage? via default_rule — curator only.
end
