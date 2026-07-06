defmodule AshStac.Integration.PgstacIntegrationTest do
  use ExUnit.Case, async: false

  alias AshStac.Pgstac

  @moduletag :integration

  setup_all do
    opts = [
      hostname: System.get_env("PGHOST", "localhost"),
      port: System.get_env("PGPORT", "5439") |> String.to_integer(),
      username: System.get_env("PGUSER", "username"),
      password: System.get_env("PGPASSWORD", "password"),
      database: System.get_env("PGDATABASE", "postgis")
    ]

    {:ok, conn} = Postgrex.start_link(opts)

    on_exit(fn ->
      if Process.alive?(conn), do: GenServer.stop(conn)
    end)

    %{conn: conn}
  end

  test "checks pgSTAC and reads seeded data", %{conn: conn} do
    assert {:ok, _versions} = Pgstac.check(conn)
    assert {:ok, collection} = Pgstac.get_collection(conn, "example-cogs")
    assert collection.id == "example-cogs"

    assert {:ok, [%AshStac.Item{id: "example-item"}]} =
             Pgstac.search_items(conn, %{"collections" => ["example-cogs"], "limit" => 1})
  end
end
