module Review
  # Centralizes the three filter keys that scope the review flow.
  # Both the controller and the helper read from params the same way so a
  # future filter key only has to be added in one place.
  module FilterParams
    ALLOWED_KEYS = %i[source category story_status].freeze

    # Extracts the three review filter keys from a params-like object.
    # ActionController::Parameters is explicitly permitted before slicing
    # because Rails 8 refuses to_h on unfiltered parameters.
    # When compact: true (default), blank values are dropped so session-key
    # construction treats e.g. "?source=" the same as no source.
    def self.from(params, compact: true)
      permitted = params.is_a?(ActionController::Parameters) ? params.permit(*ALLOWED_KEYS) : params
      sliced = permitted.to_h.slice(*ALLOWED_KEYS.map(&:to_s))
      sliced = sliced.transform_keys(&:to_sym)
      compact ? sliced.compact_blank : sliced
    end
  end
end
