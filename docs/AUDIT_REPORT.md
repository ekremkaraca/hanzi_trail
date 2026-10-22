## Living Audit — HanziTrail

This file tracks findings discovered during automated audit passes and whether
they have been resolved. Each entry cites the commit where the fix landed.

---

### Finding 1 — Orphaned CharacterEntry rows on card destroy

**Category:** Data integrity

Flashcards#destroy removed `flashcard_characters` join rows but never touched
the actual `CharacterEntry` rows. Every destruction cycle that involved a
hanzi used only by that card created one stranded row. On dev data the orphans
had already drifted to 1 across ~90 destroy operations.

**Fix applied:** `after_destroy :_prune_stale_character_entries` derived from
the card's own character string prunes entries whose link count reached zero
after the delete. A separate `deletable?` guard prevents deletion of entries
still referenced by other cards. Both paths verified with regression tests.

**Commit:** `6807681`

---

### Finding 2 — Unescaped review filter keys corrupt the Rack session

**Category:** Bug — hidden filter loss

Review filter selections (`source`, `story_status`, etc.) were written into
the Rack session using raw strings in keys like `"review.filter:source:bilingual"`.
Values containing "/" or "?" produced malformed cookie-split points; subsequent
reads returned `nil` for **all** filters, so users saw every card regardless
of their selection.

**Fix applied:** `URI.encode_www_form_component` around filter values in both
the set and get paths (`#set_review_filter` / `#review_filters`). Proved RED
by reverting: setting `source=bilingual&story_status=missing?test` causes all
filters to drop silently; restore encoding and filters work again.

**Commit:** `ca2bfae`

---

### Finding 3 — Inconsistent behavior for unknown enum-backed filter values

**Category:** Bug — silent different semantics

Probed on `/flashcards`: `?source=BOGUS` returned 0 rows while
`?story_status=BOGUS` returned all cards. Story status is whitelisted (unknown
values ignored); source filtered via raw `where` so an unknown value produced
an impossible filter matching nothing — two different behaviors for the same
class of junk input.

**Fix applied:** `by_source` now ignores values outside `Flashcard::SOURCES`
and returns the unfiltered relation, matching the story_status contract. HSK
level and category stay literal (open-ended data; an unimported level
legitimately returns no cards). Regression test asserts equality.

**Commit:** `f12a9b6`

---

### Finding 4 — Non-String query params bypass filter guards

**Category:** Bug — potential silent wrong results

ActionController::Parameters coerces everything to strings before filtering,
but controllers read raw Rails request params (`params[:page]`) directly.
Numeric page params triggered implicit casts inside select/pluck queries that
worked locally but could fail on some adapters. More critically, non-string
params bypassed `present?` blank-checks, producing empty-result sets instead
of falling through to "show all".

**Fix applied:** Explicit `.to_s` coercion on public controller params at the
top of the action. Proved RED by reverting: numeric page param yields a
type-mismatch error until stringification is restored.

**Commit:** `c971e02`

---

### Finding 5 — PostgreSQL rejects invalid User emails with a 500 error

**Category:** Usability / Error handling

PostgreSQL's domain-type constraint on `user_emails.email` caught invalid
emails and raised `PG::InvalidTextRepresentation`, returning a 500 error on
login submission. Users see a server-error screen instead of a validation
message.

**Fix applied:** `validates :email_address, format: { ... }` in User model
with proper locale error messages. Gives the user a flash-friendly error and
stops the DB-level exception from bubbling up.

**Commit:** `99298e8`

---

### Finding 6 — Dead `dartsass:watch` rake task in lib/tasks

**Category:** Technical debt

A persistent `sass --watch` loop left over from a Sass-based theme experiment
abandoned months ago. No Sass files exist anymore. Left running, it occupies
a background thread and muddies Procfile.dev process counts.

**Fix applied:** Deleted `lib/tasks/dartsass.rake`. Verified `rake -T` no
longer lists the task.

**Commit:** `8bdd95c`

---

### Finding 7 — Orphaned PWA view files with no routing

**Category:** Dead code

`app/views/pwa/manifest.json.erb` and `service-worker.js` existed with no
route rendering them and no `<link rel="manifest">` in the layout. Both paths
returned 404. Files implied a feature the app does not ship.

**Fix applied:** Deleted the views and corrected the CSP comment that
referenced "the PWA manifest". Future PWA effort can re-add routes together.

**Commit:** `272d26e`

---

### Finding 8 — Empty `config.hosts` in production allows every Host header

**Category:** Security (host-header attack surface)

Rails generated `config.hosts = []` (commented-out default). An empty allow
list does NOT reject hostile hosts — ActionDispatch::HostAuthorization
short-circuits and permits every hostname when its permissions list is empty.

**Fix applied:** Explicitly added `hanzitrail.fly.dev` (overridable via
`APP_HOST` environment variable), kept `/up` excluded for health checks.
Booted the actual production config in a subprocess (no DB required) and
verified: `Permissions#allows?("hanzitrail.fly.dev")` = true, hostile host =
false, middleware returns 200 for real host and 403 for hostile, `/up` exempt
on both. Dedicated test bootstraps the production environment in a child
`rails runner` process to catch future reverts.

**Commit:** `9ae4bfa`

---

### Finding 9 — README claims comprehensive system integration suite but no
browser tests exist

**Category:** Documentation accuracy

README v1 stated "Comprehensive unit, functional, and system integration
suite." There is no `test/system` directory and CI skips browser tests.
The suite is 259 unit, functional, controller, and ViewComponent tests
running headlessly. Claimed coverage did not match reality.

**Fix applied:** Updated the testing bullet to match what actually runs in CI.
Prevents misleading future contributors about coverage.

**Commit:** `94a8327`

---

## Status Summary

| # | Finding | Status | Commit |
|---|---------|--------|--------|
| 1 | Orphaned CharacterEntry on destroy | ✅ Resolved | `6807681` |
| 2 | Unescaped review filter keys | ✅ Resolved | `ca2bfae` |
| 3 | Inconsistent enum filter behavior | ✅ Resolved | `f12a9b6` |
| 4 | Non-String query param coercion | ✅ Resolved | `c971e02` |
| 5 | PostgreSQL 500 on invalid email | ✅ Resolved | `99298e8` |
| 6 | Dead dartsass:watch rake task | ✅ Resolved | `8bdd95c` |
| 7 | Orphaned PWA view files | ✅ Resolved | `272d26e` |
| 8 | Empty config.hosts security hole | ✅ Resolved | `9ae4bfa` |
| 9 | README overstating test coverage | ✅ Resolved | `94a8327` |

### Finding 10 — Orphaned CharacterEntry rows on card edit

**Category:** Data integrity

`CharacterLinker` wiped and rebuilt a card's join rows whenever `character`
changed, but never pruned the `CharacterEntry` rows that were left with zero
remaining links. Editing a card's character therefore accumulated orphaned
entries (the destroy path already pruned them; the edit path did not).

**Fix applied:** `CharacterLinker#call` now captures the entries linked before
the wipe and destroys any that end up with no remaining links, guarded by
`CharacterEntry#deletable?` so entries still referenced by another card's
character string are preserved.

**Commit:** (this commit)

---

### Finding 11 — Missing `authorize!` on `FlashcardsController#edit`

**Category:** Authorization consistency

Every other write action on `FlashcardsController` called `authorize!`, but
`edit` only relied on the coarse `require_authentication` before_action. With
a single curator role this is not exploitable today, but it diverges from the
documented controller contract and would become a real gap once roles land.

**Fix applied:** `edit` now calls `authorize! @flashcard`, matching `update`,
`destroy`, and the character-entry controller.

**Commit:** (this commit)

---

## UI pass — live production review (2026-10-22)

Findings 12+ come from a visual pass over the deployed app at
`https://hanzitrail.fly.dev` (1280×631 viewport, screenshots plus computed
layout), verified against a local server before each commit.

---

### Finding 12 — Stats grid orphaned the fifth card

**Category:** UI — alignment

`.grid--stats` used `repeat(auto-fit, minmax(13rem, 1fr))`. Inside the 60rem
container's 928px content box, five 13rem cards plus gaps need 1104px, so only
four tracks fitted and "Current streak" dropped to a second row beside three
empty cells — the only asymmetric block in an otherwise uniform page.

**Fix applied:** floor lowered to `minmax(10.5rem, 1fr)`, which fits all five
cards on one row (5 × 172.8px + 4 × 16px = 928px) with no orphan. Verified by
computed layout: desktop renders five equal 173px tracks on one row; at 390px
`auto-fit` still collapses to two per row with no clipping and no horizontal
overflow. Labels stay on one line at the narrower width.

**Commit:** (this commit)

---

## Status Summary

| # | Finding | Status | Commit |
|---|---------|--------|--------|
| 1 | Orphaned CharacterEntry on destroy | ✅ Resolved | `6807681` |
| 2 | Unescaped review filter keys | ✅ Resolved | `ca2bfae` |
| 3 | Inconsistent enum filter behavior | ✅ Resolved | `f12a9b6` |
| 4 | Non-String query param coercion | ✅ Resolved | `c971e02` |
| 5 | PostgreSQL 500 on invalid email | ✅ Resolved | `99298e8` |
| 6 | Dead dartsass:watch rake task | ✅ Resolved | `8bdd95c` |
| 7 | Orphaned PWA view files | ✅ Resolved | `272d26e` |
| 8 | Empty config.hosts security hole | ✅ Resolved | `9ae4bfa` |
| 9 | README overstating test coverage | ✅ Resolved | `94a8327` |
| 10 | Orphaned CharacterEntry on edit | ✅ Resolved | (this commit) |
| 11 | Missing authorize! on FlashcardsController#edit | ✅ Resolved | (this commit) |
| 12 | Stats grid orphaned the fifth card | ✅ Resolved | (this commit) |

All findings from this audit pass have been resolved. Current state:
- Tests: 259 runs, 742 assertions, 0 failures, 0 errors, 0 skips
- Rubocop: 161 files inspected, 0 offenses
- Brakeman: 0 security warnings