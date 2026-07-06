# AshStac

`AshStac` is a small Elixir library for working with STAC documents on top of a
pgSTAC database.

It keeps the boundaries explicit:

- pgSTAC owns storage, indexing, and search semantics.
- STAC documents stay JSON-safe and preserve extension fields.
- Ash is an optional facade for host applications.
- TiTiler.PgSTAC remains a separate tile service.

## What Is Included

- STAC 1.1.0 Collection and Item structs.
- Embedded Asset and Link structs.
- JSON encode/decode with unknown field preservation.
- Core STAC 1.1.0 required-field validation.
- A thin Postgrex-backed pgSTAC adapter.
- Optional Ash resources/actions over the adapter.
- TiTiler.PgSTAC URL helpers.
- A minimal Docker Compose stack for local exploration.

## What Is Not Included

- pgSTAC migrations owned by Ash.
- A full STAC API server.
- CQL2 parsing in Elixir.
- Tile rendering or proxying.
- Asset signing or auth policy.
- A large ingestion framework.

## Basic Document Usage

```elixir
{:ok, item} =
  AshStac.item(%{
    "type" => "Feature",
    "stac_version" => "1.1.0",
    "id" => "example-item",
    "collection" => "example-cogs",
    "geometry" => %{"type" => "Point", "coordinates" => [0, 0]},
    "bbox" => [0, 0, 0, 0],
    "properties" => %{"datetime" => "2024-01-01T00:00:00Z"},
    "links" => [%{"rel" => "collection", "href" => "http://example.test/collections/example-cogs"}],
    "assets" => %{"cog" => %{"href" => "s3://bucket/example.tif"}},
    "proj:epsg" => 4326
  })

AshStac.Item.to_map(item)["proj:epsg"]
```

Collections must have `"type" => "Collection"`. Items must have
`"type" => "Feature"` and a `properties.datetime` key. Items whose `geometry` is
`nil` may omit `bbox`; serialization preserves the required `geometry: nil`
field instead of dropping it.

## pgSTAC Adapter

Use a Postgrex connection and keep all pgSTAC calls behind `AshStac.Pgstac`.

```elixir
{:ok, conn} =
  Postgrex.start_link(
    hostname: "localhost",
    port: 5439,
    username: "username",
    password: "password",
    database: "postgis"
  )

{:ok, _versions} = AshStac.Pgstac.check(conn)
{:ok, collection} = AshStac.Pgstac.get_collection(conn, "example-cogs")
{:ok, items} = AshStac.Pgstac.search_items(conn, %{"collections" => ["example-cogs"]})
```

`search_items/2` decodes each returned feature as a full `AshStac.Item`. Use raw
`search/2` when passing `fields` projections or when you want the pgSTAC
FeatureCollection exactly as returned.

## Ash Facade

The Ash resources are manual-action facades. They do not own pgSTAC tables, do
not provide an Ash data layer, and still require the caller to pass a connection
argument. Use them when that shape fits a host Ash application; otherwise call
`AshStac.Pgstac` directly.

```elixir
query =
  Ash.Query.for_read(AshStac.Ash.Collection, :get, %{
    conn: conn,
    id: "example-cogs"
  })

{:ok, [record]} = Ash.read(query, domain: AshStac.Ash.Domain)
record.document
```

## TiTiler.PgSTAC URLs

```elixir
AshStac.TiTiler.collection_tile_url(
  "http://localhost:8081",
  "example-cogs",
  %{z: 1, x: 2, y: 3},
  assets: ["cog"],
  format: :png
)
```

## Local Stack

Start pgSTAC, seed data, and TiTiler:

```sh
docker compose up
```

The example stack exposes:

- pgSTAC/Postgres on `localhost:5439`
- TiTiler.PgSTAC on `localhost:8081`

Run fast tests:

```sh
mix test
```

Run the full local check suite:

```sh
mix check
```

Install the pre-commit hook:

```sh
pipx install pre-commit
pre-commit install
```

Run the opt-in pgSTAC integration test after the Compose stack is healthy:

```sh
mix test --include integration
```

See `guides/pgstac_contract.md` for the adapter contract and supported version
range.

## License

MIT. See `LICENSE`.
