# Backlog

Known deferred work, each item citing where it came from.

## Product decisions pending

- **`draft` story status is unreachable** — nothing assigns it
  (`sync_story_status` only produces missing/curated; the form doesn't
  permit it), yet filters and badges offer it. Either wire a curation
  workflow that sets it or drop the status. Origin: audit §1.
- **Index truncation notice / pagination** — `/flashcards` caps at 200
  silently; dev data fits, full HSK import won't. Pagy or a visible
  "showing first 200" note. Origin: audit §1.
- **Session progress counter lifetime** — per-filter counters persist
  across days and keys accumulate in the cookie. Consider day-scoping
  the counter or pruning stale keys. Origin: audit §1.
- **Per-user review attribution** — `review_attempts.user_id` (nullable)
  when multi-user stats matter; today all practice feeds global stats.
  Origin: auth design discussion.

## Auth hardening

- **Roles (curator vs admin)** — `manage?` in `ApplicationPolicy` is the
  single insertion point; destroy-only-admin rules slot in without
  touching controllers. Origin: authz design discussion.
- **Invite-code signup** — code from credentials gating a registration
  flow; account creation is CLI-only until then. Origin: authn design.
- **Password-reset mailer** — the Rails generator's mailer was removed
  (no SMTP on Fly). Restore it with `SMTP_*` config; reset links must
  point at the Caddy/prod https origin. CLI reset works meanwhile.
- **Session sweep** — recurring job deleting stale `Session` rows
  (server-side expiry per the Rails security guide); solid_queue +
  `config/recurring.yml` are already wired.
- **Login throttle observability** — rate limiting returns a redirect
  today; consider a flash counter or metrics after a real login exists.

## SRS / learning quality

- **Real interval scheduling** — fixed intervals (1m/1d/3d/7d) ignore
  `review_count` and history; the attempt table already supports
  SM-2-style growth. Rename `difficulty` (it stores the last rating).
  Origin: audit §1.
- **HSK re-import policy** — importer skips persisted cards, so curated
  cards matching HSK data never gain `hsk_level`/`source`. Decide
  backfill semantics. Origin: audit §1.

## Ops / misc

- **Upload body cap mirror** — if uploads ever land, add
  `request_body max_size` to the Caddyfile (comment marks the spot) and
  a Rack-level limiter for prod. Origin: Caddy §8.
- **CSP report endpoint / tightening** — drop `'unsafe-eval'` only by
  moving Alpine to its CSP build (template-based; not worth it now).
  Origin: CSP §5.
- **CJK font note** — headless/CI browsers without CJK fonts render
  tofu boxes; real devices are fine. Cosmetic for screenshot tooling
  only. Origin: browser audit passes.
