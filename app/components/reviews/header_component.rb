module Reviews
  class HeaderComponent < ViewComponent::Base
    def initialize(remaining_due_count:)
      @remaining_due_count = remaining_due_count
    end

    private

    attr_reader :remaining_due_count
  end
end
