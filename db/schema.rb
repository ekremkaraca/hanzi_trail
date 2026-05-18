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

ActiveRecord::Schema[8.1].define(version: 2026_05_18_152427) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "flashcards", force: :cascade do |t|
    t.string "category"
    t.string "character", null: false
    t.datetime "created_at", null: false
    t.string "difficulty", default: "new", null: false
    t.string "hsk_level"
    t.string "meaning", null: false
    t.datetime "next_review_at", null: false
    t.string "pinyin", null: false
    t.integer "review_count", default: 0, null: false
    t.string "source"
    t.text "story"
    t.string "story_status", default: "missing", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_flashcards_on_category"
    t.index ["character"], name: "index_flashcards_on_character", unique: true
    t.index ["hsk_level"], name: "index_flashcards_on_hsk_level"
    t.index ["next_review_at"], name: "index_flashcards_on_next_review_at"
    t.index ["source", "hsk_level"], name: "index_flashcards_on_source_and_hsk_level"
    t.index ["source"], name: "index_flashcards_on_source"
    t.index ["story_status"], name: "index_flashcards_on_story_status"
  end
end
