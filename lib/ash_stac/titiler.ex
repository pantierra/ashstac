defmodule AshStac.TiTiler do
  @moduledoc """
  URL helpers for TiTiler.PgSTAC.

  TiTiler remains a separate service. These helpers only build URLs for callers
  that want to link to tiles, TileJSON, previews, or search registration.
  """

  @default_tms "WebMercatorQuad"

  @type tile :: %{z: non_neg_integer(), x: non_neg_integer(), y: non_neg_integer()}

  @doc """
  Builds a collection tile URL.
  """
  @spec collection_tile_url(String.t(), String.t(), tile(), keyword()) :: String.t()
  def collection_tile_url(base_url, collection_id, tile, opts \\ []) do
    base_url
    |> join([
      "collections",
      collection_id,
      "tiles",
      tile_matrix_set(opts),
      tile.z,
      tile.x,
      tile.y
    ])
    |> with_format(opts)
    |> with_query(opts)
  end

  @doc """
  Builds an item tile URL.
  """
  @spec item_tile_url(String.t(), String.t(), String.t(), tile(), keyword()) :: String.t()
  def item_tile_url(base_url, collection_id, item_id, tile, opts \\ []) do
    base_url
    |> join([
      "collections",
      collection_id,
      "items",
      item_id,
      "tiles",
      tile_matrix_set(opts),
      tile.z,
      tile.x,
      tile.y
    ])
    |> with_format(opts)
    |> with_query(opts)
  end

  @doc """
  Builds a search tile URL from a registered TiTiler.PgSTAC search id.
  """
  @spec search_tile_url(String.t(), String.t(), tile(), keyword()) :: String.t()
  def search_tile_url(base_url, search_id, tile, opts \\ []) do
    base_url
    |> join(["searches", search_id, "tiles", tile_matrix_set(opts), tile.z, tile.x, tile.y])
    |> with_format(opts)
    |> with_query(opts)
  end

  @doc """
  Builds a collection TileJSON URL.
  """
  @spec collection_tilejson_url(String.t(), String.t(), keyword()) :: String.t()
  def collection_tilejson_url(base_url, collection_id, opts \\ []) do
    base_url
    |> join(["collections", collection_id, tile_matrix_set(opts), "tilejson.json"])
    |> with_query(opts)
  end

  @doc """
  Builds the search registration URL.
  """
  @spec search_register_url(String.t()) :: String.t()
  def search_register_url(base_url), do: join(base_url, ["searches", "register"])

  defp tile_matrix_set(opts), do: Keyword.get(opts, :tile_matrix_set, @default_tms)

  defp with_format(url, opts) do
    case Keyword.get(opts, :format) do
      nil -> url
      format -> url <> "." <> to_string(format)
    end
  end

  defp with_query(url, opts) do
    params =
      opts
      |> Keyword.take([:assets, :expression, :asset_as_band, :rescale, :colormap_name])
      |> Enum.flat_map(&query_pair/1)

    case URI.encode_query(params) do
      "" -> url
      query -> url <> "?" <> query
    end
  end

  defp query_pair({:assets, assets}) when is_list(assets), do: Enum.map(assets, &{"assets", &1})
  defp query_pair({key, value}) when not is_nil(value), do: [{to_string(key), to_string(value)}]
  defp query_pair(_pair), do: []

  defp join(base_url, parts) do
    path =
      Enum.map_join(parts, "/", fn part ->
        URI.encode(to_string(part), &URI.char_unreserved?/1)
      end)

    String.trim_trailing(base_url, "/") <> "/" <> path
  end
end
