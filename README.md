# HanziTrail

Story-based Mandarin flashcard app for learning technical vocabulary.

## Goal

HanziTrail helps learners remember Mandarin characters through:

- character stories
- pinyin
- meanings
- technical usage examples
- spaced repetition

## Stack

- Ruby on Rails
- Hotwire
- Bulma
- PostgreSQL
- Minitest

## Development

```bash
bin/setup
bin/rails server
```

## Data Sources

Some vocabulary data is based on the excellent
[complete-hsk-vocabulary](https://github.com/drkameleon/complete-hsk-vocabulary)
project by drkameleon.

The original dataset is used under its MIT license.
Additional stories, categorizations, and learning content were added for HanziTrail.

## Warning

Current security boundary:
- Flashcard CRUD is disabled at controller level until authentication is added.
- Review actions remain enabled for MVP study flow.
- Imported and seeded cards are the current source of content.
- Review state is currently global because authentication and per-user progress are not implemented yet.
- Speech synthesis depends on browser and system voices.
