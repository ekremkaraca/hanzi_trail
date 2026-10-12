# Architecture — HanziTrail as it works today

Rails 8.1 / Ruby 4.0.7 monolith. Single-user-scale by design; the
boundaries section of the README lists what is deliberately deferred.

## Request path

```
Fly edge → Thruster (HTTP/2, compression) → Puma → Rails
dev: Caddy (TLS :8443) → Puma (:3000)          see Caddyfile
```

- Production enforces `force_ssl` + `assume_ssl`; dev mirrors TLS via the
  Caddy proxy so `request.ssl?` and Secure-cookie paths are exercisable
  locally. `assume_ssl` stays off in dev on purpose.
- CSP is enforced (`config/initializers/content_security_policy.rb`):
  same-origin everything, per-request `SecureRandom` nonces for the
  importmap inline tags, `'unsafe-eval'` solely for Alpine's expression
  compiler, `style-src 'self'` (no inline styles anywhere).

## Styling

No preprocessor. Pure CSS v3.1 is vendored under
`app/assets/stylesheets/vendor/` for structure (grid/forms/tables);
`app/assets/stylesheets/application.css` is one hand-written cascade:
tokens → base elements → utilities → components. Vocabulary is BEM-ish
(`.btn--primary`, `.badge--warning`, `.notice--danger`, `.field`,
`.form-card`). The rating actions are colour-coded by meaning
(red/amber/blue/green). Legacy Bulma/Pico class names are banned.

## Domain model

- `Flashcard` — character, pinyin, meaning, story layer (story,
  components, literal_meaning, mnemonic, usage_note), SRS state
  (`difficulty`, `review_count`, `next_review_at`). DB check constraints
  mirror the enum validations.
- `ReviewAttempt` — append-only audit row per rating; `Scheduler` writes
  it in the same transaction as the card mutation, under a row lock.
- `CharacterEntry` + `FlashcardCharacter` — one row per distinct hanzi,
  join rows per card position. `CharacterLinker` maintains them;
  `Flashcard`'s `after_save` relink callback fires whenever `character`
  changes, so links can never go stale via the UI.

## Review flow (the core loop)

1. `ReviewsController#show` builds a `Review::Queue` from
   `Review::FilterParams` (source/category/story_status — the single
   source of truth for filter keys, also used for the session progress
   key and redirect URLs).
2. Rating = `PATCH /review/:flashcard_id` → `Review::Scheduler`: row
   lock, due-check inside the lock (double-submit safe), fixed intervals
   again=1m / hard=1d / good=3d / easy=7d, attempt row, session counter
   increment.
3. Per-filter progress counters live in the cookie session; reset is an
   explicit `PATCH /review/reset` (never a GET side effect).
4. Day-scoped aggregates (`StreakCalculator`, `ReviewVelocity`,
   `ReviewAttempt.today`) bucket by `Time.zone` — app zone is
   `Europe/Istanbul`, not UTC.

## AuthN / AuthZ

Two layers, both fail-closed:

- **AuthN** (Rails 8 generated `authentication` concern):
  `User` + `has_secure_password`, server-side `Session` records (ip +
  user agent), `Current.session/user`, cookie `session_id` (signed,
  permanent, httponly, samesite=lax). Login rate-limited 10/3min via
  `ActionController::RateLimiting` on solid_cache. Return-to bounce via
  `session[:return_to_after_authenticating]`. No public signup;
  `bin/rails users:create[email]` is the only provisioning path.
- **AuthZ** (`action_policy`): `ApplicationPolicy` declares the nil-user
  context and a `manage? = user.present?` default rule, so undefined
  rules require a curator. Policies state public reads explicitly
  (`index?/show? = true`); note the gem pre-defines `index?/create?` as
  false stubs that never fall through to the default rule. Controllers
  combine `before_action :require_authentication, except:` (coarse,
  fail-closed for future actions) with `authorize!` per action;
  `rescue_from ActionPolicy::Unauthorized` sends guests to sign-in and
  signed-in denials back. Views gate affordances with `allowed_to?`.

The generated concern resumes the session on every request
(`before_action :resume_session`) — public pages must still know who is
signed in; `allow_unauthenticated_access` skips only the enforcement.

## Frontend runtime

importmap, no bundler. Turbo Drive for navigation; Stimulus owns
side-effects (review keyboard/speech, flash auto-dismiss with an
animationend-independent fallback); Alpine owns local UI state
(`reviewCard`, `mobileNav`, `collapsible`, `textCounter`). Keyboard:
Space toggles the answer (never hijacked by focused controls), 1–4 rate
even with a button focused — the guards differ per key on purpose.

## Persistence & background

PostgreSQL (Fly). Solid Cache / Queue / Cable share the database; their
tables are bootstrapped by `bin/rails db:prepare_solid` in the release
command because `db:prepare` only migrates the primary (see
DECISION_LOG §6). No application jobs yet; recurring clearance of
finished queue jobs is configured for production.

## Testing

Minitest: models, services, controllers, ViewComponent rendering,
helpers; `sign_in_as` integration helper; policy unit tests via
`Policy#apply`. CI gate: rubocop + brakeman + bundler-audit + suite
(see `.github/workflows` / `config/ci.rb`).
