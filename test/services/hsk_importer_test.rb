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
    # The importer should also wire the character-entry links for exploration views.
    assert_equal [ "爱" ], flashcard.character_entries.order("flashcard_characters.position").pluck(:character)
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

  test "imports the common-sense form instead of the capitalized headword" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_sense_selection.json"),
      hsk_level: "old-1"
    )

    importer.call

    flashcard = Flashcard.find_by!(character: "书")

    assert_equal "shū", flashcard.pinyin
    assert_equal "book; letter", flashcard.meaning
  end

  test "honors an explicit preferred reading over the first common-sense form" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_sense_selection.json"),
      hsk_level: "old-1"
    )

    importer.call

    flashcard = Flashcard.find_by!(character: "那")

    assert_equal "nà", flashcard.pinyin
    assert_equal "that", flashcard.meaning
  end

  test "keeps the headword when it is the entry's only form" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_sense_selection.json"),
      hsk_level: "old-1"
    )

    importer.call

    flashcard = Flashcard.find_by!(character: "中国")

    assert_equal "Zhōng guó", flashcard.pinyin
    assert_equal "China", flashcard.meaning
  end

  test "raises descriptively when entry has an empty forms array" do
    importer = HskImporter.new(
      path: Rails.root.join("test/fixtures/files/hsk_empty_forms.json"),
      hsk_level: "old-1"
    )

    error = assert_raises(HskImporter::ImportError) { importer.call }
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

  test "treats a character a concurrent import just inserted as already imported" do
    path = Rails.root.join("tmp/hsk_race.json")
    File.write(path, [
      {
        "simplified" => "赛",
        "forms" => [
          { "transcriptions" => { "pinyin" => "sài" }, "meanings" => [ "compete" ] }
        ]
      }
    ].to_json)

    # Simulate a concurrent import inserting 赛 between
    # our SELECT and INSERT: the INSERT loses the unique
    # race and must not poison the whole import.
    # (Minitest 6 dropped Object#stub, so swap save!
    # explicitly and restore it afterwards.)
    save = Flashcard.instance_method(:save!)
    Flashcard.define_method(:save!) do |*|
      raise ActiveRecord::RecordNotUnique.new("stub insert race")
    end

    begin
      assert_no_difference "Flashcard.count" do
        assert_nothing_raised { HskImporter.import!(path: path, hsk_level: "old-1") }
      end
    ensure
      Flashcard.define_method(:save!, save)
    end
  ensure
    File.delete(path) if File.exist?(path)
  end

  test "imported cards are due immediately (pacing is the cap's job)" do
    HskImporter.import!(
      path: Rails.root.join("test/fixtures/files/hsk_v3_sample.json"),
      hsk_level: "new-1"
    )

    # The old import-time stagger parked cards for weeks; pacing now
    # lives entirely in DueFlashcards' daily cap.
    freeze_time do
      assert_in_delta Time.current, Flashcard.find_by!(character: "爱").next_review_at, 1.minute
      assert_in_delta Time.current, Flashcard.find_by!(character: "爱好").next_review_at, 1.minute
      assert_in_delta Time.current, Flashcard.find_by!(character: "八").next_review_at, 1.minute
    end
  end

  test "a mid-import failure keeps already-committed chunks" do
    # 105 entries with CHUNK_SIZE 100: the last chunk fails, the first
    # must survive so a re-run resumes instead of rolling back everything
    # (the Fly scale-to-zero failure mode this chunking was added for).
    entries = Array.new(105) do |i|
      { "simplified" => "字#{i}", "forms" => [ { "transcriptions" => { "pinyin" => "zì #{i}" }, "meanings" => [ "sense #{i}" ] } ] }
    end
    path = Rails.root.join("tmp/hsk_chunk_failure.json")
    File.write(path, entries.to_json)

    original = Flashcard.instance_method(:save!)
    Flashcard.define_method(:save!) do
      raise ActiveRecord::RecordInvalid, self if character == "字104"

      original.bind_call(self)
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      HskImporter.import!(path: path, hsk_level: "new-1")
    end

    assert_equal 100, Flashcard.where("character LIKE '字%'").count,
      "chunk 1 must stay committed while the failing chunk rolls back"
  ensure
    Flashcard.define_method(:save!, original)
    File.delete(path) if File.exist?(path)
  end

  test "single-character entries backfill the radical, multi-character ones do not" do
    HskImporter.import!(
      path: Rails.root.join("test/fixtures/files/hsk_v3_sample.json"),
      hsk_level: "new-1"
    )

    assert_equal "爫", CharacterEntry.find_by!(character: "爱").radical
    assert_equal "八", CharacterEntry.find_by!(character: "八").radical
    # 好 only ever appears inside the multi-character 爱好 entry, whose
    # radical belongs to the headword 爱 - it must not be attributed to 好.
    assert_nil CharacterEntry.find_by!(character: "好").radical
  end

  test "radical backfill never overwrites curator values" do
    existing = CharacterEntry.create!(character: "爱", radical: "手")

    HskImporter.import!(
      path: Rails.root.join("test/fixtures/files/hsk_v3_sample.json"),
      hsk_level: "new-1"
    )

    assert_equal "手", existing.reload.radical
  end
end
