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

  test "raises when file does not exist" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/nonexistent.json"),
      hsk_level: "old-1"
    )

    error = assert_raises(HskImporter::ImportError) { importer.call }
    assert_match(/does not exist/, error.message)
  end

  test "raises when JSON is malformed" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_malformed.json"),
      hsk_level: "old-1"
    )

    error = assert_raises(HskImporter::ImportError) { importer.call }
    assert_match(/Invalid JSON/, error.message)
  end

  test "skips duplicate characters already in the database" do
    Flashcard.create!(
      character: "好",
      pinyin: "hao3",
      meaning: "good",
      source: "hsk",
      hsk_level: "old-1",
      next_review_at: Time.current,
      difficulty: "new"
    )

    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_duplicates.json"),
      hsk_level: "old-2"
    )

    assert_no_difference "Flashcard.count" do
      importer.call
    end
  end

  test "skips duplicate characters within the same import file" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_duplicates.json"),
      hsk_level: "old-1"
    )

    assert_difference "Flashcard.count", 1 do
      importer.call
    end

    flashcard = Flashcard.find_by!(character: "好")
    assert_equal "hsk", flashcard.source
    assert_equal "old-1", flashcard.hsk_level
  end

  test "raises when entry is missing simplified key" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_missing_keys.json"),
      hsk_level: "old-1"
    )

    assert_raises(HskImporter::ImportError) { importer.call }
  end

  test "raises when form is missing meanings key" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_missing_form_keys.json"),
      hsk_level: "old-1"
    )

    assert_raises(HskImporter::ImportError) { importer.call }
  end

  test "raises descriptively when entry has an empty forms array" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_empty_forms.json"),
      hsk_level: "old-1"
    )

    error = assert_raises(RuntimeError) { importer.call }
    assert_match(/empty forms array/, error.message)
  end

  test "does not create partial records on import failure" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_missing_keys.json"),
      hsk_level: "old-1"
    )

    assert_no_difference "Flashcard.count" do
      importer.call rescue nil
    end
  end

  test "rolls back nothing when file is not found" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/nonexistent.json"),
      hsk_level: "old-1"
    )

    assert_no_difference "Flashcard.count" do
      importer.call rescue nil
    end
  end

  test "raises import error for missing file" do
    error = assert_raises(HskImporter::ImportError) do
      HskImporter.import!(path: "missing.json", level: "old-1")
    end

    assert_match "does not exist", error.message
  end

  test "raises import error for empty forms array" do
    path = Rails.root.join("tmp/empty_forms.json")
    File.write(path, [ { "s" => "爱", "forms" => [] } ].to_json)

    assert_raises(HskImporter::ImportError) do
      HskImporter.import!(path: path, level: "old-1")
    end
  ensure
    File.delete(path) if File.exist?(path)
  end
end
