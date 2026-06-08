# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_01_140002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "character_entries", force: :cascade do |t|
    t.string "character", null: false
    t.datetime "created_at", null: false
    t.string "meaning"
    t.text "notes"
    t.string "pinyin"
    t.string "radical"
    t.datetime "updated_at", null: false
    t.index ["character"], name: "index_character_entries_on_character", unique: true
  end

  create_table "flashcard_characters", force: :cascade do |t|
    t.bigint "character_entry_id", null: false
    t.datetime "created_at", null: false
    t.bigint "flashcard_id", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["character_entry_id"], name: "index_flashcard_characters_on_character_entry_id"
    t.index ["flashcard_id", "character_entry_id"], name: "idx_on_flashcard_id_character_entry_id_77372bf1cb", unique: true
    t.index ["flashcard_id", "position"], name: "index_flashcard_characters_on_flashcard_id_and_position", unique: true
    t.index ["flashcard_id"], name: "index_flashcard_characters_on_flashcard_id"
  end

  create_table "flashcards", force: :cascade do |t|
    t.string "category"
    t.string "character", null: false
    t.text "components"
    t.datetime "created_at", null: false
    t.string "difficulty", default: "new", null: false
    t.string "hsk_level"
    t.text "literal_meaning"
    t.string "meaning", null: false
    t.text "mnemonic"
    t.datetime "next_review_at", null: false
    t.string "pinyin", null: false
    t.integer "review_count", default: 0, null: false
    t.string "source", default: "curated", null: false
    t.text "story"
    t.string "story_status", default: "missing", null: false
    t.datetime "updated_at", null: false
    t.text "usage_note"
    t.index ["category"], name: "index_flashcards_on_category"
    t.index ["character"], name: "index_flashcards_on_character", unique: true
    t.index ["hsk_level"], name: "index_flashcards_on_hsk_level"
    t.index ["next_review_at"], name: "index_flashcards_on_next_review_at"
    t.index ["source", "hsk_level"], name: "index_flashcards_on_source_and_hsk_level"
    t.index ["source"], name: "index_flashcards_on_source"
    t.index ["story_status"], name: "index_flashcards_on_story_status"
    t.check_constraint "difficulty::text = ANY (ARRAY['new'::character varying::text, 'again'::character varying::text, 'easy'::character varying::text, 'good'::character varying::text, 'hard'::character varying::text])", name: "flashcards_difficulty_check"
    t.check_constraint "review_count >= 0", name: "flashcards_review_count_check"
    t.check_constraint "source::text = ANY (ARRAY['curated'::character varying::text, 'hsk'::character varying::text])", name: "flashcards_source_check"
    t.check_constraint "story_status::text = ANY (ARRAY['missing'::character varying::text, 'draft'::character varying::text, 'curated'::character varying::text])", name: "flashcards_story_status_check"
  end

  create_table "review_attempts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "flashcard_id", null: false
    t.string "rating", null: false
    t.datetime "reviewed_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flashcard_id", "reviewed_at"], name: "index_review_attempts_on_flashcard_id_and_reviewed_at"
    t.index ["flashcard_id"], name: "index_review_attempts_on_flashcard_id"
    t.index ["rating"], name: "index_review_attempts_on_rating"
    t.index ["reviewed_at"], name: "index_review_attempts_on_reviewed_at"
    t.check_constraint "rating::text = ANY (ARRAY['again'::character varying::text, 'easy'::character varying::text, 'good'::character varying::text, 'hard'::character varying::text])", name: "review_attempts_rating_check"
  end

  add_foreign_key "flashcard_characters", "character_entries"
  add_foreign_key "flashcard_characters", "flashcards"
  add_foreign_key "review_attempts", "flashcards"
end
