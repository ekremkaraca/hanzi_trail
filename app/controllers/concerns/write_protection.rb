module WriteProtection
  extend ActiveSupport::Concern

  private

  def require_write_access
    redirect_to flashcards_path,
      alert: "Editing is disabled until authentication is added"
  end
end
