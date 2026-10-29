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

ActiveRecord::Schema[8.1].define(version: 2026_10_29_063937) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "character_entries", force: :cascade do |t|
    t.string "character", null: false
    t.datetime "created_at", null: false
    t.string "meaning"
    t.text "notes"
    t.string "pinyin"
    t.string "radical"
    t.datetime "updated_at", null: false
    t.string "pinyin_source"
    t.index ["character"], name: "index_character_entries_on_character", unique: true
    t.index ["pinyin_source"], name: "index_character_entries_on_pinyin_source"
    t.check_constraint "pinyin_source IS NULL OR (pinyin_source::text = ANY (ARRAY['manual'::character varying, 'dictionary'::character varying]::text[]))", name: "character_entries_pinyin_source_check"
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
    t.string "pinyin_sort_key", default: "", null: false
    t.jsonb "tokens", default: [], null: false
    t.text "audio_url"
    t.integer "audio_duration_ms"
    t.integer "position"
    t.float "ease", default: 2.5, null: false
    t.integer "success_streak", default: 0, null: false
    t.index ["category"], name: "idx_flashcards_trgm_category", opclass: :gin_trgm_ops, using: :gin
    t.index ["category"], name: "index_flashcards_on_category"
    t.index ["character"], name: "idx_flashcards_trgm_character", opclass: :gin_trgm_ops, using: :gin
    t.index ["character"], name: "index_flashcards_on_character", unique: true
    t.index ["hsk_level"], name: "index_flashcards_on_hsk_level"
    t.index ["meaning"], name: "idx_flashcards_trgm_meaning", opclass: :gin_trgm_ops, using: :gin
    t.index ["next_review_at"], name: "index_flashcards_on_next_review_at"
    t.index ["pinyin"], name: "idx_flashcards_trgm_pinyin", opclass: :gin_trgm_ops, using: :gin
    t.index ["pinyin_sort_key"], name: "index_flashcards_on_pinyin_sort_key"
    t.index ["position"], name: "index_flashcards_on_position"
    t.index ["source", "hsk_level"], name: "index_flashcards_on_source_and_hsk_level"
    t.index ["source"], name: "index_flashcards_on_source"
    t.index ["story_status"], name: "index_flashcards_on_story_status"
    t.index ["tokens"], name: "index_flashcards_on_tokens", using: :gin
    t.check_constraint "difficulty::text = ANY (ARRAY['new'::character varying::text, 'again'::character varying::text, 'easy'::character varying::text, 'good'::character varying::text, 'hard'::character varying::text])", name: "flashcards_difficulty_check"
    t.check_constraint "ease >= 1.3::double precision AND ease <= 2.5::double precision", name: "flashcards_ease_range"
    t.check_constraint "review_count >= 0", name: "flashcards_review_count_check"
    t.check_constraint "source::text = ANY (ARRAY['curated'::character varying::text, 'hsk'::character varying::text])", name: "flashcards_source_check"
    t.check_constraint "story_status::text = ANY (ARRAY['missing'::character varying::text, 'draft'::character varying::text, 'curated'::character varying::text])", name: "flashcards_story_status_check"
    t.check_constraint "success_streak >= 0", name: "flashcards_success_streak_non_negative"
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

  create_table "sentence_tokens", force: :cascade do |t|
    t.bigint "sentence_id", null: false
    t.integer "position", null: false
    t.string "token", null: false
    t.boolean "is_punctuation", default: false, null: false
    t.integer "letters_count"
    t.boolean "visible_default", default: true, null: false
    t.string "lemma"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sentence_id", "position"], name: "index_sentence_tokens_on_sentence_id_and_position", unique: true
    t.index ["sentence_id"], name: "index_sentence_tokens_on_sentence_id"
    t.index ["token"], name: "index_sentence_tokens_on_token"
  end

  create_table "sentence_word_translations", force: :cascade do |t|
    t.bigint "sentence_id", null: false
    t.bigint "sentence_token_id"
    t.string "word_form", null: false
    t.string "gloss", null: false
    t.integer "rank", default: 0
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sentence_id", "word_form"], name: "index_sentence_word_translations_on_sentence_id_and_word_form"
    t.index ["sentence_id"], name: "index_sentence_word_translations_on_sentence_id"
    t.index ["sentence_token_id"], name: "index_sentence_word_translations_on_sentence_token_id"
    t.index ["word_form"], name: "index_sentence_word_translations_on_word_form"
  end

  create_table "sentences", force: :cascade do |t|
    t.string "external_id"
    t.string "source", default: "curated", null: false
    t.string "language", default: "de", null: false
    t.text "phrase", null: false
    t.text "translation_sentence"
    t.text "translation_gloss"
    t.text "audio_url"
    t.integer "audio_duration_ms"
    t.integer "position"
    t.string "difficulty_level"
    t.boolean "is_favorite", default: false, null: false
    t.jsonb "grammar_tips", default: {}
    t.text "grammar_table_html"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_sentences_on_external_id"
    t.index ["position"], name: "index_sentences_on_position"
    t.index ["source", "language"], name: "index_sentences_on_source_and_language"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.index ["expires_at"], name: "index_sessions_on_expires_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "user_sentence_states", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "sentence_id", null: false
    t.jsonb "revealed_mask", default: []
    t.integer "review_count", default: 0, null: false
    t.integer "lapse_count", default: 0, null: false
    t.float "ease_factor", default: 2.5
    t.integer "interval_days", default: 0
    t.datetime "next_review_at"
    t.datetime "last_reviewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["next_review_at"], name: "index_user_sentence_states_on_next_review_at"
    t.index ["sentence_id"], name: "index_user_sentence_states_on_sentence_id"
    t.index ["user_id", "sentence_id"], name: "index_user_sentence_states_on_user_id_and_sentence_id", unique: true
    t.index ["user_id"], name: "index_user_sentence_states_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "flashcard_characters", "character_entries"
  add_foreign_key "flashcard_characters", "flashcards"
  add_foreign_key "review_attempts", "flashcards"
  add_foreign_key "sentence_tokens", "sentences", on_delete: :cascade
  add_foreign_key "sentence_word_translations", "sentence_tokens", on_delete: :cascade
  add_foreign_key "sentence_word_translations", "sentences", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "user_sentence_states", "sentences", on_delete: :cascade
  add_foreign_key "user_sentence_states", "users", on_delete: :cascade
end
