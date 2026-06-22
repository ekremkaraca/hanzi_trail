module Review
  class FilterParams
    FILTER_KEYS = %i[source category story_status].freeze

    def self.from(params)
      raw_params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params

      FILTER_KEYS.each_with_object({}) do |key, filters|
        # Read from a plain hash copy so Rails does not log unrelated form keys as unpermitted.
        value = raw_params[key.to_s] || raw_params[key]
        # Keep URLs/session keys stable by treating blank filter values as absent.
        filters[key] = value if value.present?
      end
    end
  end
end
