require "test_helper"

module CharacterEntries
  class PinyinImporterTest < ActiveSupport::TestCase
    setup do
      @dictionary = Rails.root.join("test/fixtures/files/pinyin_sample.txt")
    end

    test "fills a blank entry and records the dictionary provenance" do
      entry = character_entries(:one) # 网
      entry.update_columns(pinyin: nil, pinyin_source: nil)

      report = PinyinImporter.import!(path: @dictionary)

      assert_equal 1, report.filled
      assert_equal "wǎng", entry.reload.pinyin
      assert_equal "dictionary", entry.pinyin_source
    end

    test "leaves an entry that already has a pinyin untouched" do
      entry = character_entries(:one)
      entry.update_columns(pinyin: "wǎng", pinyin_source: "manual")

      report = PinyinImporter.import!(path: @dictionary)

      assert_equal 0, report.filled
      assert_equal "wǎng", entry.reload.pinyin
      assert_equal "manual", entry.pinyin_source
    end

    test "force re-imports dictionary-sourced values but not manual ones" do
      # Keep the fixture entry out of the import so the counts stay exact.
      character_entries(:one).update_columns(pinyin: "wǎng", pinyin_source: "manual")

      imported = CharacterEntry.create!(character: "江")
      manual = CharacterEntry.create!(character: "重", pinyin: "zhòng", pinyin_source: "manual")

      # The first import fills the blank entry and records its provenance.
      PinyinImporter.import!(path: @dictionary)
      assert_equal "dictionary", imported.reload.pinyin_source

      report = PinyinImporter.import!(path: @dictionary, force: true)

      assert_equal 1, report.filled
      assert_equal "jiāng", imported.reload.pinyin
      assert_equal "zhòng", manual.reload.pinyin
      assert_equal "manual", manual.pinyin_source
    end

    test "reports characters the dictionary does not cover" do
      entry = CharacterEntry.create!(character: "鑫")

      report = PinyinImporter.import!(path: @dictionary)

      assert_equal 1, report.uncovered
      assert_nil entry.reload.pinyin
    end

    test "a dry run reports what would change without writing" do
      entry = character_entries(:one)
      entry.update_columns(pinyin: nil, pinyin_source: nil)

      report = PinyinImporter.import!(path: @dictionary, dry_run: true)

      assert_equal 1, report.filled
      assert_nil entry.reload.pinyin
    end

    test "raises when the dictionary file is missing" do
      error = assert_raises(ArgumentError) do
        PinyinImporter.import!(path: Rails.root.join("test/fixtures/files/nonexistent.txt"))
      end

      assert_match(/not found/, error.message)
    end
  end
end
