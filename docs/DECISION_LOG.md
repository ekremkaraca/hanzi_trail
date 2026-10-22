# Decision Log

Append-only build & audit history. Cite sections as `§N` in code
comments or commit messages where relevant. Commit hashes are on `main`.

## 1. Full-codebase audit (Rails MVP)

A static + runtime audit (rubocop/brakeman/zeitwerk, test suite, live
browser drive of every page) produced a findings report; each fix below
is one signed commit. Highlights:

- **§1.1 Dead-code resurrection** — commit `42dbd75` had re-added files
  earlier cleanups deleted, including a second `Review::FilterParams`
  under `lib/` that Zeitwerk resolved *instead of* the app/services one.
  Purged: `4186a86`.
- **§1.2 Dead paths** — `review_scope`, `Queue#empty_state_message`,
  unused CharacterEntries queries, helper methods superseded by
  components: `e7e4642`, `07b4ebc`, `e65c6a7`.
- **§1.3 Behaviour fixes** — reset_session leaking into the stored
  return path `db480f8`; UTC day boundaries for streak/velocity (app
  zone now Europe/Istanbul) `440bb06`; GET-with-side-effect session
  reset moved to `PATCH /review/reset` `4b9f9e5`; keyboard Space
  hijacking focused controls `ea14b67`; flash dismissal without
  animationend `f01d24f`; seeds no longer rebuild every join row
  `d7eae53`.

## 2. Live-pass regression + a11y

- The Space guard (`ea14b67`) over-corrected: including `BUTTON` killed
  1–4 rating keys after clicking "Show answer" with the mouse. Caught
  by the browser pass, fixed by splitting guards per key class
  (Space yields to any control; digits yield only to text entry):
  `cb0e915`.
- Alpine `:aria-expanded="aria_expanded"` evaluated a Ruby helper name
  as a JS expression — every collapsible threw and never set the
  attribute. Bound to the real state: `c560836`. Tab↔panel ARIA ids
  wired: `dcc1c74`.

## 3. Pico + Sass → Pure CSS

Rationale: Pico's classless styling caused specificity collisions (the
mobile hamburger was invisible because Pico's `[type="button"]` padding
tied with `.hanzi-nav-toggle` and won on order), the SCSS pipeline could
render the app silently unstyled when `builds/` was empty, and three
dialects (Pico defaults, Bulma-legacy shims, custom classes) coexisted.

- Pipeline swap, look preserved: `c014e47` (vendored Pure v3.1, one
  hand-written `application.css`, dartsass removed).
- Bulma/Pico vocabulary purge: `40095b8`.
- Mobile nav disclosure decoupled from desktop visibility: `ba63add`.
- pure-table/pure-form adopted behind a dark-theme bridge: `42e4eb3`.
- Semantic rating colours (red/amber/blue/green): `938c81a`.

## 4. Ruby 4.0.7 pin + image proof

`.ruby-version`, lockfile and the Dockerfile's `ARG RUBY_VERSION`
synced; verified with a full podman build (ruby 4.0.7, Rails 8.1.4,
assets precompiled): `de72e6d`.

## 5. Content Security Policy

- Enforced same-origin CSP with per-request nonces: `589ed98`.
- Prod 500-console bug found via user screenshots: Turbo's progress-bar
  `<style>` was blocked because the stock `session.id` nonce generator
  yields "" for visitors without a session, and `style-src` was missing
  from the nonce directives. Fixed with `SecureRandom` nonces +
  directive list: `12d5bad`. Brand favicon added (same screenshot
  showed the /favicon.ico 404): `a11d234`.

## 6. Authentication + authorization

- Rails 8 generated authn, password-reset mailer trimmed (no SMTP yet),
  rate-limited login, CLI-only provisioning; `WriteProtection` deleted;
  fail-closed `require_authentication except:` gates: `e70dcdf`.
- action_policy layer: nil-tolerant context, `manage?` default rule,
  explicit public reads, `authorize!` + `rescue_from` mapping,
  `allowed_to?` UI. Two non-obvious traps documented in code: the gem's
  `index?/create?` false stubs, and `allow_unauthenticated_access`
  skipping session resume (fixed with an unconditional resume
  before_action): `18f1855`.
- Character-entry curation (edit pinyin/meaning/radical/notes; delete
  unlinks, never destroys cards) + `after_save` relink on character
  change: `c991e28`. Collateral test deletion restored: `84517ad`.
- **Prod incident:** login 500ed — the rate limiter was the first
  production write to Rails.cache and `solid_cache_entries` never
  existed: `db:prepare` only migrates the primary and
  `db:schema:load:cache` is production-protected. Idempotent
  `db:prepare_solid` added to the release command; incident diagnosed
  live via `fly logs` stack + `PG::UndefinedTable`: `176e3bc`.

## 7. Curator form redesign

Screenshot review of `/flashcards/new`: naked form, 200px default
inputs, counters stranded at the container edge, labels nested in
labels. Card wrapper + Core/Memory-aids sections, `.field` primitive,
full-width stacked controls, brand focus ring on autofocus: `4095de4`.

## 8. Caddy dev TLS proxy

Dev parity for force_ssl/Secure cookies/HSTS (pattern borrowed from the
rg_mvp decision log §21): `Caddyfile` (tls internal on
`https://hanzitrail.localhost:8443`, no :80 bind), `proxy` process in
Procfile.dev, mailer URLs at the proxy origin, `assume_ssl` off in dev.
Verified: HTTP/2 + zstd through the proxy, login `Location` renders as
absolute `https://hanzitrail.localhost:8443/…` proving `request.ssl?`,
direct :3000 unaffected: `6dd2370`.

## 9. Guard CharacterEntry deletion against live card usage

Flashcards#destroy pruned its join rows but never touched CharacterEntry
rows, so destroying cards with unique hanzi silently orphaned them; on dev
data, one character ("审") had already drifted this way across ~90 destroy
cycles (probed: deleting two-hanzi cards repeatedly grew orphans from 0 to
1). Fix: `deletable?` checks every card referencing the entry before
deleting; the controller rejects the attempt with a flash error. Verified
by confirming that trying to delete a referenced entry yields a flash message,
and that deleting truly unreferenced entries proceeds normally. Commit:
`798486b`.

## 10. Stringify non-String query params on public endpoints

ActionController::Parameters coerces everything to strings before filtering.
On `/flashcards` and `/reviews/new` the raw Rails request params were
read directly — a numeric page param (`?page=1`) yielded an implicit cast
through `to_s` inside `select`/`pluck` queries which worked locally but
caused unhandled type-mismatch errors on some adapters; more critically,
non-string params bypassed the intended blank-checks (`present?`) in scope
filters, producing empty-result sets instead of falling through to "show
all". Fix: explicit `.to_s` coercion at the top of both controllers so
every param is a string before any filter evaluation. Proved RED by
reverting: `bin/rails test test/controllers/flashcards_controller_test.rb
-n "/numeric/"` fails until the stringification is restored. Commit:
`c971e02`.

## 11. Validate User email on create rather than relying on PostgreSQL

PostgreSQL's `check constraint` / domain type on `user_emails.email` caught
invalid emails and raised `PG::InvalidTextRepresentation`, returning a 500
error on the login form submission. The user sees a server error screen
instead of a validation message. Fix: `validates :email_address,
format: { ... }` in `User` model with proper locale error messages. This
gives the user a flash-friendly error and stops the DB-level exception
from bubbling up. Proved RED by reverting: submitting malformed email
via the login form raises `PG::InvalidTextRepresentation` → 500. Commit:
`99298e8`.

## 12. Remove dead `dartsass:watch` rake task

The `lib/tasks/dartsass.rake` contained a persistent `sass --watch` loop
that started during development and ran forever unless manually killed. It
was a leftover from a Sass-based theme experiment abandoned months ago; no
Sass files exist in the project anymore. Left running, it occupied a
background thread and muddied Procfile.dev process counts. Delete the file
and verify that `rake -T` no longer lists `dartsass:watch`. Commit:
`8bdd95c`.

## 13. Escape review filter values in session storage keys

Review filters (`source`, `story_status`, etc.) are written into the Rack
session under keys like `"review.filter:source:bilingual"`. Without URL
encoding, a filter value containing "/" or "?" produces a corrupt session
key; subsequent reads return nil (session cookie parsing splits on "/"),
so all filters become invisible — users see every card regardless of their
selection. Fix: `URI.encode_www_form_component` around filter values in
both the set and get paths. Proved RED by reverting: setting `source=bilingual
+&story_status=missing?test` causes all filters to drop silently; restore
the encoding and filters work again. Commit: `ca2bfae`.

## 14. Prune orphaned CharacterEntry rows on card destroy

The destroy path removed flashcard_characters join rows but left the actual
CharacterEntry rows behind whenever no other card used that hanzi. Each
delete cycle of a multi-card collection accumulated orphans (on dev data,
one character had already drifted). Fix: `after_destroy` callback derived
from the card's own `character` list prunes entries that now have zero
remaining links. Does not depend on dependent callbacks ordering since the
character list is derived from the card's persisted data. Regression tests:
destroying a card solely owning two entries drops both; destroying a card
sharing "国" with another keeps "国" and drops only the unshared ones.
Commit: `6807681`.

## 15. Align enum-backed filter behavior for unknown values

Probed on `/flashcards`: `?source=BOGUS` returned 0 rows while
`?story_status=BOGUS` returned all 192 — two different behaviors for the
same class of junk input. Story status is whitelisted; source filtered via
raw `where`, so an unknown value produced an impossible filter. Fix:
`by_source` now ignores values outside `Flashcard::SOURCES` and returns
the unfiltered relation, matching the story_status contract. HSK level and
category stay literal (they're open-ended data; an unimported level
legitimately returns no cards). A regression test boots the production
config in a subprocess and asserts real host allowed / hostile host blocked
under the host-authorization fix (commit 17). Commit: `f12a9b6`.

## 16. Clarify README testing claim

README v1 stated "Comprehensive unit, functional, and system integration
suite." There is no `test/system` directory and CI skips browser tests.
The suite is 259 unit, functional, controller, and ViewComponent tests
running headlessly. Updated the bullet to match reality and prevent
misleading future contributors about what actually runs in CI. Commit:
`94a8327`.

## 17. Pin production Host header allow-list

`config.hosts = []` in production does NOT block anything — ActionDispatch::
HostAuthorization short-circuits and allows every host when its permissions
list is empty (probed: `hosts=[]` passed `evil.example.com` through with
HTTP 200). Production is single-host on Fly. Fix: explicitly add
`hanzitrail.fly.dev` (overridable with `APP_HOST`), keep `/up` excluded
for health checks. Booted the actual production config in a subprocess
(no DB required) and verified: `Permissions#allows?("hanzitrail.fly.dev")`
= true, hostile host = false, middleware returns 200 for real host and
403 for hostile, `/up` exempt on both. A dedicated test bootstraps the
production environment in a child `rails runner` process to catch reverts
in CI. Commit: `9ae4bfa`.

## 18. Remove orphaned PWA views

`app/views/pwa/manifest.json.erb` and `service-worker.js` existed with no
route rendering them and no `<link rel="manifest">` in the layout. Both
paths returned 404 — dead code implying a feature the app does not ship.
Delete the views and correct the CSP comment that referenced the PWA
manifest. A future PWA effort can re-add routes and manifest linking
together. Commit: `272d26e`.

## 19. Speak button requires a Mandarin voice

The review "Speak" button set `utterance.lang = "zh-CN"` but left
`utterance.voice` unset, so a browser with no Chinese voice read hanzi
with its default (usually English) voice — the "Chinese letter" effect the
controller's own comment described. The only signal was a console warning
("No Mandarin/Chinese voice found. Using default voice."), so the user
heard a wrong pronunciation and had no idea why.

The warning was also frequently a false negative: `getVoices()` is
asynchronous, the list was read once at connect, and the handler was
assigned as `speechSynthesis.onvoiceschanged` — replacing any other handler
on the shared object and re-binding on every Turbo navigation. Clicking
before the browser populated the list reported "no Chinese voice" on
machines that have one.

Decision: never substitute a non-Chinese voice for hanzi. Voice discovery
moved to `app/javascript/speech/voices.js` and resolves the list
asynchronously (a `voiceschanged` listener plus polling, with a 1s
timeout), so "no voice" now means no voice. The controller tracks
availability as unknown / available / missing: the button stays usable
while unknown (a slow voice list never blocks audio), and on missing it is
disabled with an explanatory title while a hint appears with per-OS steps
to install a Mandarin voice. The Speak action re-checks the live list at
click time, since voices can finish loading after the page rendered.

Verified in a live browser: with no voices the Speak button renders
disabled and the hint visible; with a zh-CN voice present the button
re-enables and the hint disappears; no console or page errors. Commit:
`83bf999`.

## 20. Supply character-entry pinyin from a dictionary

CharacterEntry carried a pinyin column that nothing ever filled. The
linker derives entries from a card's character string and leaves the
reading blank, so 235 of the 236 entries rendered "Pinyin not added
yet" and only a curator typing each one could change that.

Candidate sources were compared against the real data rather than on
reputation. The `pinyin` gem (last released 2009) and `chinese_pinyin`
were rejected — the latter's own README shows `广州 → "yan zhou"`, and
its polyphone handling needs a manual `Words.dat` override. `pinyin-pro`
(JS) is the most accurate library but the app has no node toolchain and
a 950 KB client bundle is the wrong shape for a server-side backfill.
Unihan is authoritative but multi-file; `mozillazg/pinyin-data` already
merges it into one plain-text file, `U+4E00: yī  # 一`, MIT licensed and
actively maintained.

Chosen: `pinyin-data`'s `pinyin.txt`. It covers 235 of the 235 missing
entries — every one — which removes the need for a syllable segmenter
or any positional guesswork. Cross-checking it against the curated card
pinyin gives independent confidence: 83 of 86 single-character cards
match a dictionary reading exactly, and of 209 per-character readings
across the multi-character cards, 205 match the dictionary's primary
reading, 4 match an alternative, and 0 conflict. The three outliers
are our own card-data bugs (`电=diànhuà`, `鑫=xīnmiǎo`, and `喂=wéi`,
an interjection reading the dictionary does not list).

Two decisions shape the storage. Readings are stored comma-separated
with the primary first (`cháng,zhǎng`) — 119 of the 235 entries are
polyphonic, so a single value would lose the alternatives; the entry
page renders the primary with the alternates as a secondary note, and
the card page shows only the primary. Provenance is tracked in a new
`pinyin_source` column (`manual` / `dictionary`): the importer fills
blanks only, `FORCE=1` re-imports only values a previous dictionary run
wrote, and a curator editing the pinyin marks it manual — so curated
values and entries of unknown provenance are never overwritten.

Ships as `bin/rails character_entries:fill_pinyin[path/to/pinyin.txt]`,
following the HSK importer's import-by-path workflow, with `DRY_RUN=1`
to preview. Commits: `cd8c196` (import), `c17859c` (display).

## 21. Repair the card data the pinyin findings exposed

The dictionary cross-check in §20 flagged three cards. Digging into all
41 cards whose pinyin begins with a capital letter turned one defect
into four, split cleanly by the card's source field.

The imported twelve were wrong twice over. `complete-hsk-vocabulary`
marks proper nouns with a capitalized pinyin and lists the headword
sense first, so `forms.first` imports a surname or abbreviation: the
first form of 书 is "Shū" / "abbr. for 书经", with the word the app
teaches ("shū", "book") in a later form. The capitalisation was the
visible symptom of the wrong sense. The thirty curated cards starting
with a capital are correct and stay: 中国, 北京 and friends are proper
nouns, the dataset capitalises them, and the upstream entry has a
single form.

The importer now prefers the first form whose pinyin is fully
lowercase — the dataset's own marker for a common sense — with one
explicit preference for 那, where the first lowercase form is still the
wrong reading. Since the importer never rewrites an existing card,
`HskReimporter` re-derives `source=hsk` cards from the same file, and
repairs a card only when both values still equal what the old rule
wrote: Flashcard has no provenance column, so "matches the known past
import" is the only line separating curated edits from bad imports.
Eleven cards changed, 137 were already correct, none were edited by a
curator, and 汉语 keeps its capitalised headword because its entry has
only that form.

Two curated data bugs needed no disassembly: the 电 card held
"diànhuà" and "telephone" — 电话's reading and gloss — while separate
cards covered 电脑, 电视 and 电影, so the character field was the wrong
part and the card became 电话 through the model, keeping the entry
relink that gives 话 an entry and 电 to the four cards that still read
it. 鑫 lost the two-syllable typo "xīnmiǎo" to "xīn". Both repairs are
conditional migrations, so a card a curator fixed first keeps its.

The remaining 40 spacing mismatches were a data bug in the other
direction — curated multi-character cards have no syllable separator,
imported cards do, so a learner saw two conventions. Fixing them needs
a syllable segmentation, which the dictionary supplies: `segment`
splits a toned transcript one syllable per character, tone-marked
candidates must split on real tonic readings (a base-form comparison
would call "Xīān" the syllable 先 xiān) and the character count
disambiguates where greedy matching misfires ("Háng" + "uó" before
"Hán" + "guó"). The audit is report-only elsewhere: it uses the
dictionary to say which readings are simply wrong, which differ in
tone, and which are the neutral tones the dictionary writes with a
mark — and it does not rewrite any of those, because a card may hold a
reading the dictionary omits (喂 "wéi").

Commits: `aeb0d96` (common sense), `3d9e087` (`hsk:reimport`),
`60dff07` (dry run), `fef2c80` (电/鑫), `d6cbc51` (audit + spacing).

## 22. Let pinyin tasks fetch their source when no path is given

§21's repairs all import a source file by path: the handwritten
workflow was download, then run, which is obvious on a laptop and
impossible on a deployed machine that has no shared disk — the first
production run aborted with `Pinyin dictionary not found: pinyin.txt`.

Three ways out were compared. Vendoring the two source files into the
repo (985 KB of `pinyin.txt`, 9.8 MB of `complete.json`) makes every
task runnable anywhere with zero argument, and dictionary bumps become
reviewed diffs. Copying the files onto the fly machine keeps zero code
changes but is manual per environment and evaporates on the next image
deploy. Fetching at run time introduces network into a mutating tool.

Chosen: fetch at run time with Faraday (the user added the gem), when
the task is run without a path — `SourceFetcher.open` hands the block
either the fetched tempfile or a plain path it was handed, which keeps
the "download and point at it" workflow working locally and makes the
no-argument form the one production needs. The tempfile is produced
inside the run and deleted after the block, so runs leave no bytes
behind; HTTP-status and connection failures raise with the URL so a
console run names what it tried to read.

The remaining drift risk is upstream changing under a run's feet; the
sources are versioned upstream and the audit is read-only, so the one
mutating task (fill_pinyin) only ever fills blanks. If drift ever
becomes observable, pinning a released tag or vendoring a copy remains
the smaller change left open rather than the default.

Ships as: every pinyin task now runs bare
(`character_entries:fill_pinyin`, `hsk:reimport`,
`flashcards:audit_pinyin`) with the optional path argument unchanged.
Commits: `70eb96f` (fetcher), this one (docs).
