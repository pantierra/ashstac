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

## Deliberately Unsupported

- Running pgSTAC migrations from Elixir.
- Implementing CQL2 parsing in Elixir.
- Replacing `pypgstac` ingestion.
- Owning pgSTAC table migrations through AshPostgres.
- Proxying or rendering tiles.

## SQL Boundary

All direct SQL belongs in `AshStac.Pgstac`. Other modules should work with typed
STAC documents and adapter functions instead of reaching into pgSTAC tables.
