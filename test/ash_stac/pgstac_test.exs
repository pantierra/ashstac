defmodule AshStac.PgstacTest do
  use ExUnit.Case, async: true

  alias AshStac.{Collection, Item, Pgstac}

  defmodule FakeConn do
    def query("SHOW server_version", []) do
      {:ok, %{rows: [["16.4 (Debian 16.4-1)"]]}}
    end

    def query("SELECT pgstac.version()", []) do
      {:ok, %{rows: [["0.9.2"]]}}
    end

    def query("SELECT content FROM pgstac.collections WHERE id = $1", ["sentinel-2"]) do
      {:ok, %{rows: [[collection_document()]]}}
    end

    def query("SELECT content FROM pgstac.items WHERE collection = $1 AND id = $2", [
          "sentinel-2",
          "item-1"
        ]) do
      {:ok, %{rows: [[item_document()]]}}
    end

    def query("SELECT pgstac.search($1)", [%{"collections" => ["sentinel-2"]}]) do
      {:ok,
       %{
         rows: [
           [%{"type" => "FeatureCollection", "features" => [item_document()], "links" => []}]
         ]
       }}
    end

    def query(sql, _params) when is_binary(sql) do
      cond do
        String.contains?(sql, "INSERT INTO pgstac.collections") -> {:ok, %{rows: []}}
        String.contains?(sql, "INSERT INTO pgstac.items") -> {:ok, %{rows: []}}
      end
    end

    defp collection_document do
      %{
        "stac_version" => "1.1.0",
        "id" => "sentinel-2",
        "description" => "Sentinel-2 scenes",
        "license" => "proprietary",
        "extent" => %{
          "spatial" => %{"bbox" => [[-180, -90, 180, 90]]},
          "temporal" => %{"interval" => [["2020-01-01T00:00:00Z", nil]]}
        },
        "links" => [%{"rel" => "self", "href" => "https://example.test/collections/sentinel-2"}]
      }
    end

    defp item_document do
      %{
        "type" => "Feature",
        "stac_version" => "1.1.0",
        "id" => "item-1",
        "collection" => "sentinel-2",
        "geometry" => %{"type" => "Point", "coordinates" => [0, 0]},
        "bbox" => [0, 0, 0, 0],
        "properties" => %{"datetime" => "2024-01-01T00:00:00Z"},
        "links" => [
          %{"rel" => "collection", "href" => "https://example.test/collections/sentinel-2"}
        ],
        "assets" => %{"data" => %{"href" => "s3://bucket/item.tif"}}
      }
    end
  end

  test "checks pgSTAC compatibility" do
    assert {:ok, %{postgres: %Version{}, pgstac: %Version{}}} = Pgstac.check(FakeConn)
  end

  test "reads and upserts collections" do
    assert {:ok, %Collection{id: "sentinel-2"} = collection} =
             Pgstac.get_collection(FakeConn, "sentinel-2")

    assert {:ok, ^collection} = Pgstac.upsert_collection(FakeConn, collection)
  end

  test "reads and upserts items" do
    assert {:ok, %Item{id: "item-1"} = item} = Pgstac.get_item(FakeConn, "sentinel-2", "item-1")
    assert {:ok, ^item} = Pgstac.upsert_item(FakeConn, item)
  end

  test "searches items from pgSTAC FeatureCollection results" do
    assert {:ok, [%Item{id: "item-1"}]} =
             Pgstac.search_items(FakeConn, %{"collections" => ["sentinel-2"]})
  end
end
