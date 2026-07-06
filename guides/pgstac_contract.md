# pgSTAC Contract

`AshStac` treats pgSTAC as an external database API. The library does not create,
migrate, or reshape pgSTAC-owned tables.

## Supported Baseline

- PostgreSQL: `>= 13.0.0`
- pgSTAC: `>= 0.9.0 and < 0.10.0`
- TiTiler.PgSTAC: expected to run as a separate service against the same database

## Adapter-Owned Operations

The first adapter supports only:

- Read a collection by `id`.
- Upsert a collection STAC JSON document.
- Read an item by `collection` and `id`.
- Upsert an item STAC JSON document.
- Run a structured item search through pgSTAC.
- Check PostgreSQL and pgSTAC versions at runtime.

`search_items/2` expects pgSTAC to return complete STAC Item features that can
be decoded by `AshStac.Item`. Use `search/2` for raw FeatureCollection responses,
partial `fields` projections, or responses that should not be validated as full
items.

## Document Validation Boundary

`AshStac` validates the STAC 1.1.0 core shape needed to safely round-trip
Collections and Items:

- Collections must have `"type": "Collection"` and required core fields.
- Items must have `"type": "Feature"`, required core fields, and a
  `properties.datetime` key.
- Items with `null` geometry may omit `bbox`; serialization preserves the
  required `geometry: null` field.

Extension fields are preserved but not schema-validated.

## Deliberately Unsupported

- Running pgSTAC migrations from Elixir.
- Implementing CQL2 parsing in Elixir.
- Replacing `pypgstac` ingestion.
- Owning pgSTAC table migrations through AshPostgres.
- Proxying or rendering tiles.

## SQL Boundary

All direct SQL belongs in `AshStac.Pgstac`. Other modules should work with typed
STAC documents and adapter functions instead of reaching into pgSTAC tables.

## Ash Facade Boundary

The Ash resources are manual-action convenience wrappers around
`AshStac.Pgstac`. They do not define an Ash data layer, do not own database
tables, and do not replace direct adapter calls for callers that do not need Ash
resource actions.
