module Reviews
  class PreferencesComponent < ViewComponent::Base
    def initialize(show_pinyin:, filter_params:)
      @show_pinyin = show_pinyin
      @filter_params = filter_params
    end

    private

    attr_reader :show_pinyin, :filter_params
  end
end
