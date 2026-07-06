defmodule AshStac.DocumentTest do
  use ExUnit.Case, async: true

  alias AshStac.{Collection, Item, SearchQuery}

  describe "collections" do
    test "round-trips core and extension fields" do
      document = %{
        "stac_version" => "1.1.0",
        "id" => "sentinel-2",
        "description" => "Sentinel-2 scenes",
        "license" => "proprietary",
        "extent" => %{
          "spatial" => %{"bbox" => [[-180, -90, 180, 90]]},
          "temporal" => %{"interval" => [["2020-01-01T00:00:00Z", nil]]}
        },
        "links" => [%{"rel" => "self", "href" => "https://example.test/collections/sentinel-2"}],
        "assets" => %{
          "thumbnail" => %{
            "href" => "https://example.test/thumb.png",
            "type" => "image/png",
            "x-extra" => true
          }
        },
        "cube:dimensions" => %{"time" => %{"type" => "temporal"}}
      }

      assert {:ok, collection} = Collection.new(document)

      assert Collection.to_map(collection)["cube:dimensions"] == %{
               "time" => %{"type" => "temporal"}
             }

      assert Collection.to_map(collection)["assets"]["thumbnail"]["x-extra"] == true
    end

    test "reports missing required fields" do
      assert {:error, errors} = Collection.new(%{})
      assert {:missing_field, "id"} in errors
      assert {:missing_field, "links"} in errors
    end
  end

  describe "items" do
    test "round-trips item documents with embedded assets" do
      document = %{
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
        "assets" => %{"data" => %{"href" => "s3://bucket/item.tif"}},
        "proj:epsg" => 4326
      }

      assert {:ok, item} = Item.new(document)
      assert {:ok, "sentinel-2"} = Item.collection_id(item)
      assert Item.to_map(item)["proj:epsg"] == 4326
      assert Item.to_map(item)["assets"]["data"]["href"] == "s3://bucket/item.tif"
    end
  end

  describe "search queries" do
    test "preserves pass-through fields" do
      query = %{
        "collections" => ["sentinel-2"],
        "filter" => %{"op" => "=", "args" => [%{"property" => "eo:cloud_cover"}, 0]},
        "context" => true
      }

      assert {:ok, search_query} = SearchQuery.new(query)
      assert SearchQuery.to_map(search_query)["context"] == true
    end
  end
end
