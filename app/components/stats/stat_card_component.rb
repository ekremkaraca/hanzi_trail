module Stats
  class StatCardComponent < ViewComponent::Base
    def initialize(label:, value:, dom_id: nil)
      @label = label
      @value = value
      @dom_id = dom_id
    end

    private

    attr_reader :label, :value, :dom_id

    def dom_attributes
      return {} if dom_id.blank?

      { id: dom_id }
    end
  end
end
