defmodule AshStac.TiTilerTest do
  use ExUnit.Case, async: true

  alias AshStac.TiTiler

  test "builds collection tile URLs with explicit tile matrix set" do
    assert TiTiler.collection_tile_url(
             "https://tiles.example.test/",
             "sentinel-2",
             %{z: 1, x: 2, y: 3},
             assets: ["red", "green"],
             format: :png
           ) ==
             "https://tiles.example.test/collections/sentinel-2/tiles/WebMercatorQuad/1/2/3.png?assets=red&assets=green"
  end

  test "builds item and search tile URLs" do
    assert TiTiler.item_tile_url(
             "https://tiles.example.test",
             "sentinel-2",
             "item-1",
             %{z: 1, x: 2, y: 3},
             tile_matrix_set: "WorldCRS84Quad"
           ) ==
             "https://tiles.example.test/collections/sentinel-2/items/item-1/tiles/WorldCRS84Quad/1/2/3"

    assert TiTiler.search_tile_url("https://tiles.example.test", "abc123", %{z: 1, x: 2, y: 3}) ==
             "https://tiles.example.test/searches/abc123/tiles/WebMercatorQuad/1/2/3"
  end

  test "builds tilejson and search registration URLs" do
    assert TiTiler.collection_tilejson_url("https://tiles.example.test", "sentinel-2") ==
             "https://tiles.example.test/collections/sentinel-2/WebMercatorQuad/tilejson.json"

    assert TiTiler.search_register_url("https://tiles.example.test") ==
             "https://tiles.example.test/searches/register"
  end
end
