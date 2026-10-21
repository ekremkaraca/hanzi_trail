class AddExpiresAtToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :sessions, :expires_at, :datetime
    add_index :sessions, :expires_at

    # Existing rows keep working: stamp them with the same
    # TTL a fresh sign-in would get, relative to now.
    reversible do |dir|
      dir.up { execute "UPDATE sessions SET expires_at = now() + interval '2 weeks'" }
    end
  end
end
