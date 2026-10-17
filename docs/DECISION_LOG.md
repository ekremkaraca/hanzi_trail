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
Delete the views and correct the CSP comment that referenced "the PWA
manifest". A future PWA effort can re-add routes and manifest linking
together. Commit: `272d26e`.
