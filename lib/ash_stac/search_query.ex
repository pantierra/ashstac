defmodule AshStac.SearchQuery do
  @moduledoc """
  Structured STAC item-search body passed through to pgSTAC.

  This module intentionally does not parse CQL2. It keeps query JSON shaped and
  lets pgSTAC own search semantics.
  """

  alias AshStac.Document

  @known_fields [
    "collections",
    "ids",
    "bbox",
    "intersects",
    "datetime",
    "filter",
    "filter-lang",
    "query",
    "sortby",
    "fields",
    "limit"
  ]

  defstruct [
    :collections,
    :ids,
    :bbox,
    :intersects,
    :datetime,
    :filter,
    :filter_lang,
    :query,
    :sortby,
    :fields,
    :limit,
    extra: %{}
  ]

  @type t :: %__MODULE__{
          collections: [String.t()] | nil,
          ids: [String.t()] | nil,
          bbox: [number()] | nil,
          intersects: map() | nil,
          datetime: String.t() | nil,
          filter: map() | String.t() | nil,
          filter_lang: String.t() | nil,
          query: map() | nil,
          sortby: [map()] | nil,
          fields: map() | nil,
          limit: pos_integer() | nil,
          extra: map()
        }

  @spec new(t() | map()) :: {:ok, t()} | {:error, term()}
  def new(%__MODULE__{} = search_query), do: {:ok, search_query}

  def new(map) when is_map(map) do
    with :ok <- validate(map) do
      {known, extra} = Document.split_known(map, @known_fields)

      {:ok,
       %__MODULE__{
         collections: known["collections"],
         ids: known["ids"],
         bbox: known["bbox"],
         intersects: known["intersects"],
         datetime: known["datetime"],
         filter: known["filter"],
         filter_lang: known["filter-lang"],
         query: known["query"],
         sortby: known["sortby"],
         fields: known["fields"],
         limit: known["limit"],
         extra: extra
       }}
    end
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = search_query) do
    %{
      "collections" => search_query.collections,
      "ids" => search_query.ids,
      "bbox" => search_query.bbox,
      "intersects" => search_query.intersects,
      "datetime" => search_query.datetime,
      "filter" => search_query.filter,
      "filter-lang" => search_query.filter_lang,
      "query" => search_query.query,
      "sortby" => search_query.sortby,
      "fields" => search_query.fields,
      "limit" => search_query.limit
    }
    |> Document.put_known(search_query.extra)
  end

  defp validate(map) do
    Document.collect_errors([
      list_if_present(map, "collections"),
      list_if_present(map, "ids"),
      list_if_present(map, "bbox"),
      integer_if_present(map, "limit")
    ])
  end

  defp list_if_present(map, field) do
    case Map.fetch(map, field) do
      {:ok, value} when is_list(value) -> :ok
      {:ok, value} -> {:error, {:invalid_field, field, value}}
      :error -> :ok
    end
  end

  defp integer_if_present(map, field) do
    case Map.fetch(map, field) do
      {:ok, value} when is_integer(value) and value > 0 -> :ok
      {:ok, value} -> {:error, {:invalid_field, field, value}}
      :error -> :ok
    end
  end
end
