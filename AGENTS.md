# Agent Guide

## Project Shape

`AshStac` is a small Elixir library for STAC documents backed by pgSTAC.

- pgSTAC owns database schema, indexing, and search semantics.
- STAC documents must preserve unknown extension fields exactly.
- Ash is an optional facade over the adapter, not the persistence layer.
- TiTiler.PgSTAC is a sibling service; do not proxy or render tiles here.

## Coding Rules

- Keep modules small, explicit, and data-in/data-out.
- Avoid DSLs, macros, or new abstractions until duplication is real.
- Prefer simple functions around STAC maps before adding framework layers.
- Keep direct SQL inside `AshStac.Pgstac`.
- Keep later Ash/Phoenix-facing layers thin; pgSTAC behavior should not leak past the adapter.
- Do not add AshPostgres migrations for pgSTAC-owned tables.
- Do not implement CQL2 parsing, asset signing, auth, ingestion pipelines, or tile rendering unless explicitly requested.
- Prefer preserving STAC JSON compatibility over normalizing documents into many structs or tables.
- Validate STAC 1.1.0 core required fields first; do not add broad extension schema validation unless a real caller needs it.
- Keep examples minimal and disposable. The library is the product, not the demo app.

## Scope Discipline

- Add Ash resources/actions only when they wrap stable adapter behavior.
- Keep policies, multitenancy, JSON:API, GraphQL, Phoenix exposure, caching, and host-app auth out unless explicitly requested.
- If a feature competes with pgSTAC, TiTiler.PgSTAC, or `pypgstac`, prefer integration over reimplementation.
- Tests should match risk: unit-test document validation and URL builders; use real pgSTAC only for adapter integration.

## Checks

Run before finishing changes:

```sh
mix check
```

This runs formatting, compile warnings-as-errors, Credo strict, and tests.

Docker-backed pgSTAC tests are opt-in:

```sh
mix test --include integration
```

## Local Stack

Use `docker compose up` for local pgSTAC, seed data, and TiTiler.PgSTAC. The normal test suite must not require Docker.
