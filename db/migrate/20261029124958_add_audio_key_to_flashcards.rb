# Audio keys point at immutable object-store objects, so a plain nullable
# string is all the schema needs. No index: finding keyless cards for the
# render task scans 4k rows, which is milliseconds — an index would be
# migration surface without a payoff at this size.
class AddAudioKeyToFlashcards < ActiveRecord::Migration[8.1]
  def change
    add_column :flashcards, :audio_key, :string
  end
end
