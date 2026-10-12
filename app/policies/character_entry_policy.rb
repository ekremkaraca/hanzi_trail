class CharacterEntryPolicy < ApplicationPolicy
  # Entry pages are public; curing their metadata is curator-only.
  # create? is intentionally absent — entries exist only through
  # CharacterLinker, never through the web UI.
  def show?
    true
  end
end
