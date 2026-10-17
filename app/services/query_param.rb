# Normalizes untrusted query-string values into a scalar String (or nil) before
# they reach model scope APIs that assume String input.
#
# A query string can deliver shapes a filter never means:
#   ?query[]=a        -> Array, which raises NoMethodError inside sanitize_sql_like
#   ?query[a][b]=c    -> nested Hash, same failure
# and a NUL byte (?query=%00) is rejected by PostgreSQL ("string contains null
# byte"), 500ing otherwise-public pages with no auth required.
#
# Non-String shapes are treated as ABSENT rather than coerced: an Array filter
# is malformed input, not a meaningful filter, and `[].to_s` would silently
# search for the literal "[]". NUL bytes are stripped so the value is safe for
# the database.
class QueryParam
  def self.scalar(value)
    return nil unless value.is_a?(String)

    value.delete("\u0000").presence
  end
end
