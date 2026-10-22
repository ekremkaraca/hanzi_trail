# HanziTrail

A story-based Mandarin flashcard application tailored for learning technical vocabulary.

## Goal

HanziTrail helps engineers and technical professionals retain Mandarin characters through:

- Character etymology and mnemonic stories
- Pinyin and translation mapping
- Technical usage examples and contextual focus
- Native Spaced Repetition Systems (SRS)

## Features

- **Spaced Repetition Review:** Clean review loop with dedicated keyboard shortcut routing.
- **Character Explorer:** Deep-dive navigation into individual hanzi components.
- **Related Words & Context:** View how technical characters combine to form modern engineering terms.
- **HSK Integration:** Seeded vocabulary tracking tailored for foundational progress.

## Stack

- **Backend:** Ruby on Rails 8 (with Solid Cache / Solid Queue)
- **Frontend Interaction:** Hotwire (Turbo Drive) + Alpine.js (for localized UI state)
- **Styling:** Pure CSS (vendored primitives) + one hand-written `application.css` design layer — no preprocessor
- **Database:** PostgreSQL
- **Testing:** Minitest — unit, functional, controller and ViewComponent
  coverage (no browser/system tests; `test/system` does not exist and the
  `bin/ci` system step is disabled)

## Development

Requirements: Ruby (via mise), PostgreSQL, and [Caddy 2.x](https://caddyserver.com/) —
`bin/dev` runs Caddy as a local HTTPS proxy in front of Puma.

```bash
bin/setup
caddy trust        # once (needs sudo): install Caddy's local CA so browsers trust the cert
bin/dev            # Rails + Caddy -> https://hanzitrail.localhost:8443
```

- `https://hanzitrail.localhost:8443` — the prod-shaped origin (TLS, `request.ssl?`
  true via `X-Forwarded-Proto`, HTTP/2); use this in the browser day to day.
- `http://localhost:3000` — Puma directly, still alive for tooling/curl.
- Chrome resolves `*.localhost` natively; on Firefox, if it doesn't resolve, add
  `127.0.0.1 hanzitrail.localhost` to `/etc/hosts`.
- Curator accounts are provisioned via CLI (no public signup):
  `bin/rails users:create[you@example.com]`

## AI-Assisted, Human-Accountable

This project embraces AI tooling to accelerate development velocity—specifically for complex operations like full CSS framework migrations, boilerplate generation, and isolated view refactoring. However, this is **not** an auto-generated repository.

I operate under a strict **Human-Accountable** engineering philosophy:

* **Zero black-box merges:** No code is shipped that I cannot personally explain, debug, or rewrite from scratch.
* **Architectural ownership:** High-level systemic design, framework state boundaries, and technical tradeoffs are entirely human-driven.
* **Verified integrity:** Every single AI-assisted refactor is gated by a robust, passing test suite before it ever touches the main branch.

What this looks like in practice, from the current history: the Pico/Sass → Pure CSS migration, the authentication + action_policy stack, and the security/CSP hardening were all AI-paired. Every commit carries a `Co-Authored-By` signature and a message that states the *why*, cites the failing evidence, and records the suite count. When an AI-authored fix regressed the rating shortcuts (`cb0e915` followed `ea14b67`), the regression was caught by a live browser pass, documented, and fixed in its own commit — not silently squashed. The decision trail lives in [`docs/DECISION_LOG.md`](docs/DECISION_LOG.md).

## Data Sources

Vocabulary baselines are built upon the [complete-hsk-vocabulary](https://github.com/drkameleon/complete-hsk-vocabulary) project by drkameleon, utilized under the MIT license. All specialized technical categorizations, mnemonics, and custom story layers were designed specifically for HanziTrail.

Per-character pinyin readings come from the [pinyin-data](https://github.com/mozillazg/pinyin-data) map by mozillazg (MIT), which is derived from the Unicode Consortium's Unihan database. Download `pinyin.txt` and import it with `bin/rails character_entries:fill_pinyin[path/to/pinyin.txt]`; the import only fills blank entries, and values a curator has typed are never overwritten.

## MVP Architectural Boundaries & Warnings

Please note the current state of the application boundaries:

* **Curator auth is live:** Flashcard and character-entry CRUD requires a signed-in curator (Rails 8 `has_secure_password` sessions + `action_policy`). There is no public signup — accounts are provisioned via `bin/rails users:create[email]`, and password reset is CLI-only until SMTP delivery exists.
* **Global review state:** Spaced repetition progress and stats remain global; per-user review attribution is deferred (see [`docs/BACKLOG.md`](docs/BACKLOG.md)).
* **Audio Synthesis:** Text-to-Speech capabilities rely entirely on native browser Web Speech API implementations and system-level Chinese voice packs.

## Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — how the app works **today** (read this first)
- [`docs/DECISION_LOG.md`](docs/DECISION_LOG.md) — append-only build & audit history; the
  `§N` markers in code comments and commit messages cite this file
- [`docs/BACKLOG.md`](docs/BACKLOG.md) — known deferred work, each item citing its origin
