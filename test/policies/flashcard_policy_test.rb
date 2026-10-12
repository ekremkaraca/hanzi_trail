require "test_helper"

# See https://actionpolicy.evilmartians.io/#/testing?id=testing-policies
class FlashcardPolicyTest < ActiveSupport::TestCase
  setup do
    @flashcard = flashcards(:network)
    @user = users(:one)
  end

  test "guests can browse" do
    assert permitted?(:index?, user: nil)
    assert permitted?(:show?, @flashcard, user: nil)
  end

  test "guests cannot write" do
    %i[create? update? destroy?].each do |rule|
      assert_not permitted?(rule, @flashcard, user: nil),
        "expected #{rule} to be denied for guests"
    end
  end

  test "curators can do everything" do
    %i[index? show? create? update? destroy?].each do |rule|
      assert permitted?(rule, @flashcard, user: @user),
        "expected #{rule} to be allowed for curators"
    end
  end

  private

  # Build the policy for a record (or the class for collection rules)
  # with a given user context. #apply (not a direct predicate call) so
  # aliases and the default_rule fallback are honoured.
  def permitted?(rule, record = Flashcard, user:)
    FlashcardPolicy.new(record, user: user).apply(rule)
  end
end
