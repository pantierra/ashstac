{:ok, conn} =
  Postgrex.start_link(
    hostname: System.get_env("PGHOST", "localhost"),
    port: System.get_env("PGPORT", "5439") |> String.to_integer(),
    username: System.get_env("PGUSER", "username"),
    password: System.get_env("PGPASSWORD", "password"),
    database: System.get_env("PGDATABASE", "postgis")
  )

{:ok, versions} = AshStac.Pgstac.check(conn)
IO.inspect(versions, label: "pgSTAC compatibility")

{:ok, collection} = AshStac.Pgstac.get_collection(conn, "example-cogs")
IO.inspect(collection.id, label: "collection")

{:ok, items} =
  AshStac.Pgstac.search_items(conn, %{"collections" => ["example-cogs"], "limit" => 1})

IO.inspect(Enum.map(items, & &1.id), label: "items")

IO.puts(
  AshStac.TiTiler.collection_tile_url(
    "http://localhost:8081",
    "example-cogs",
    %{z: 0, x: 0, y: 0},
    assets: ["cog"],
    format: :png
  )
)
