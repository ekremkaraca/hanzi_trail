module Flashcards
  module Form
    class TextAreaWithCounterComponent < ViewComponent::Base
      def initialize(form:, attribute:, char_limit:, rows:, placeholder: nil)
        @form = form
        @attribute = attribute
        @char_limit = char_limit
        @rows = rows
        @placeholder = placeholder
      end

      private

      attr_reader :form, :attribute, :char_limit, :rows, :placeholder

      def field_id
        form.field_id(attribute)
      end
    end
  end
end
