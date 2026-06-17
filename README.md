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
- **Styling:** Pico.css (Semantic, classless baseline)
- **Database:** PostgreSQL
- **Testing:** Minitest (Comprehensive unit, functional, and system integration suite)

## Development

```bash
bin/setup
bin/rails server

```

## AI-Assisted, Human-Accountable

This project embraces AI tooling to accelerate development velocity—specifically for complex operations like full CSS framework migrations, boilerplate generation, and isolated view refactoring. However, this is **not** an auto-generated repository.

I operate under a strict **Human-Accountable** engineering philosophy:

* **Zero black-box merges:** No code is shipped that I cannot personally explain, debug, or rewrite from scratch.
* **Architectural ownership:** High-level systemic design, framework state boundaries, and technical tradeoffs are entirely human-driven.
* **Verified integrity:** Every single AI-assisted refactor is gated by a robust, passing test suite before it ever touches the main branch.

## Data Sources

Vocabulary baselines are built upon the [complete-hsk-vocabulary](https://github.com/drkameleon/complete-hsk-vocabulary) project by drkameleon, utilized under the MIT license. All specialized technical categorizations, mnemonics, and custom story layers were designed specifically for HanziTrail.

## MVP Architectural Boundaries & Warnings

Please note the current state of the application boundaries:

* **Authentication Pending:** Flashcard modification (CRUD) is strictly disabled at the controller level until user authentication is introduced.
* **Global Review State:** Spaced repetition progress is currently global; multi-user session scoping will follow the authentication layer.
* **Audio Synthesis:** Text-to-Speech capabilities rely entirely on native browser Web Speech API implementations and system-level Chinese voice packs.
