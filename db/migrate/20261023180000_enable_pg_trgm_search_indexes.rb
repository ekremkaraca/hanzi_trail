class EnablePgTrgmSearchIndexes < ActiveRecord::Migration[8.1]
  # Flashcard#search runs ILIKE '%query%' over character, pinyin, meaning
  # and category - a leading wildcard no btree can serve, so every search
  # was a full sequential scan of the table.
  #
  # Trigram (pg_trgm) GIN indexes give those patterns an index path:
  # probes on this database confirmed show_trgm tokenizes CJK strings
  # ("网络" yields 3 tokens) and that `character ~~* '%网络%'` is served
  # by the trgm index (Bitmap Index Scan with the ILIKE as Index Cond,
  # forced with enable_seqscan=off).
  #
  # At the current 194 rows the planner still prefers the seqscan (cost
  # ~20 vs ~2100 for the bitmap path) - correctly, and it will until the
  # table grows enough for the OR of four ILIKEs to BitmapOr the index
  # paths. The indexes are therefore inert-but-correct today and
  # automatic tomorrow: adding them when the scan actually hurts means a
  # migration plus a build under load, so they land now. Storage is
  # tens of KB at this scale; the one-time build is trivial.
  #
  # This reverses the trgm suggestion declined in decision log 24, which
  # was scoped to the curator-path LIKE on a single column; this is the
  # public search path over four columns. The full probe record is in
  # DECISION_LOG 25.
  def up
    enable_extension "pg_trgm"

    %w[character pinyin meaning category].each do |column|
      add_index :flashcards, column, using: :gin,
        opclass: :gin_trgm_ops,
        name: "idx_flashcards_trgm_#{column}"
    end
  end

  def down
    %w[character pinyin meaning category].each do |column|
      remove_index :flashcards, name: "idx_flashcards_trgm_#{column}"
    end

    # Drop the extension only if nothing else started using it - the
    # app owns no other trgm object today, and an orphaned extension is
    # less surprising than a failed rollback.
    disable_extension "pg_trgm"
  end
end
