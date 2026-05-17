require "test_helper"

class HskImporterTest < ActiveSupport::TestCase
  test "imports hsk cards with missing story status" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_old_1_sample.json"),
      hsk_level: "old-1"
    )

    assert_difference "Flashcard.count", 1 do
      importer.call
    end

    flashcard = Flashcard.find_by!(character: "爱")

    assert_equal "hsk", flashcard.source
    assert_equal "old-1", flashcard.hsk_level
    assert_nil flashcard.story
    assert_equal "missing", flashcard.story_status
  end
end
