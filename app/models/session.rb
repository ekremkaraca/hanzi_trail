class Session < ApplicationRecord
  # Sign-in sessions are not permanent: the cookie may linger
  # on a device, but the server forgets a session once the
  # TTL elapses, so abandoned cookies become inert and old
  # rows can be purged (see the sessions:purge task).
  SESSION_TTL = 2.weeks

  belongs_to :user

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
end
