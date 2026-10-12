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
