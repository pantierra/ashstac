defmodule AshStac.Pgstac do
  @moduledoc """
  Thin adapter boundary for pgSTAC.

  The adapter deliberately keeps SQL here instead of spreading pgSTAC details
  through document, Ash, or Phoenix-facing modules.
  """

  alias AshStac.{Collection, Item, SearchQuery}
  alias AshStac.Pgstac.Contract

  @type conn :: pid() | module()
  @type result(value) :: {:ok, value} | {:error, term()}

  @doc """
  Runs the pgSTAC/Postgres compatibility checks.
  """
  @spec check(conn()) :: Contract.check()
  defdelegate check(conn), to: Contract

  @doc """
  Reads a STAC collection by id.
  """
  @spec get_collection(conn(), String.t()) :: result(Collection.t() | nil)
  def get_collection(conn, id) when is_binary(id) do
    with {:ok, rows} <-
           query_rows(conn, "SELECT content FROM pgstac.collections WHERE id = $1", [id]) do
      rows
      |> one()
      |> decode_document(Collection)
    end
  end

  @doc """
  Upserts a STAC collection document.
  """
  @spec upsert_collection(conn(), Collection.t() | map()) :: result(Collection.t())
  def upsert_collection(conn, collection) do
    with {:ok, collection} <- Collection.new(collection),
         content <- Collection.to_map(collection),
         id <- collection.id,
         {:ok, _rows} <-
           query_rows(
             conn,
             """
             INSERT INTO pgstac.collections (id, content)
             VALUES ($1, $2)
             ON CONFLICT (id) DO UPDATE SET content = EXCLUDED.content
             """,
             [id, content]
           ) do
      {:ok, collection}
    end
  end

  @doc """
  Reads a STAC item by collection id and item id.
  """
  @spec get_item(conn(), String.t(), String.t()) :: result(Item.t() | nil)
  def get_item(conn, collection_id, item_id)
      when is_binary(collection_id) and is_binary(item_id) do
    with {:ok, rows} <-
           query_rows(
             conn,
             "SELECT content FROM pgstac.items WHERE collection = $1 AND id = $2",
             [collection_id, item_id]
           ) do
      rows
      |> one()
      |> decode_document(Item)
    end
  end

  @doc """
  Upserts a STAC item document.
  """
  @spec upsert_item(conn(), Item.t() | map()) :: result(Item.t())
  def upsert_item(conn, item) do
    with {:ok, item} <- Item.new(item),
         content <- Item.to_map(item),
         {:ok, collection_id} <- Item.collection_id(item),
         id <- item.id,
         {:ok, _rows} <-
           query_rows(
             conn,
             """
             INSERT INTO pgstac.items (id, collection, content)
             VALUES ($1, $2, $3)
             ON CONFLICT (collection, id) DO UPDATE SET content = EXCLUDED.content
             """,
             [id, collection_id, content]
           ) do
      {:ok, item}
    end
  end

  @doc """
  Searches items via pgSTAC and returns typed STAC items.

  The search body is passed through as structured JSON. pgSTAC remains the owner
  of spatial, temporal, CQL2, and sorting semantics.
  """
  @spec search_items(conn(), SearchQuery.t() | map()) :: result([Item.t()])
  def search_items(conn, search_query) do
    with {:ok, search_query} <- SearchQuery.new(search_query),
         body <- SearchQuery.to_map(search_query),
         {:ok, rows} <- query_rows(conn, "SELECT pgstac.search($1)", [body]),
         {:ok, features} <- search_features(rows) do
      decode_items(features)
    end
  end

  @doc """
  Runs a pgSTAC search and returns the raw STAC FeatureCollection map.
  """
  @spec search(conn(), SearchQuery.t() | map()) :: result(map())
  def search(conn, search_query) do
    with {:ok, search_query} <- SearchQuery.new(search_query),
         body <- SearchQuery.to_map(search_query),
         {:ok, rows} <- query_rows(conn, "SELECT pgstac.search($1)", [body]) do
      rows
      |> one()
      |> case do
        nil -> {:error, :empty_search_result}
        feature_collection when is_map(feature_collection) -> {:ok, feature_collection}
        other -> {:error, {:invalid_search_result, other}}
      end
    end
  end

  defp query_rows(conn, sql, params) do
    case query(conn, sql, params) do
      {:ok, %{rows: rows}} -> {:ok, rows}
      {:error, reason} -> {:error, reason}
    end
  end

  defp query(conn, sql, params) when is_pid(conn), do: Postgrex.query(conn, sql, params)
  defp query(conn, sql, params) when is_atom(conn), do: conn.query(sql, params)

  defp one([]), do: nil
  defp one([[document]]), do: document

  defp decode_document(nil, _module), do: {:ok, nil}
  defp decode_document(document, module), do: module.new(document)

  defp search_features([[feature_collection]]) when is_map(feature_collection) do
    case Map.fetch(feature_collection, "features") do
      {:ok, features} when is_list(features) -> {:ok, features}
      {:ok, features} -> {:error, {:invalid_search_features, features}}
      :error -> {:error, :missing_search_features}
    end
  end

  defp search_features(rows), do: {:error, {:invalid_search_result, rows}}

  defp decode_items(features) do
    features
    |> Enum.reduce_while({:ok, []}, &decode_item/2)
    |> reverse_items()
  end

  defp decode_item(document, {:ok, acc}) do
    case Item.new(document) do
      {:ok, item} -> {:cont, {:ok, [item | acc]}}
      {:error, reason} -> {:halt, {:error, reason}}
    end
  end

  defp reverse_items({:ok, items}), do: {:ok, Enum.reverse(items)}
  defp reverse_items(error), do: error
end
