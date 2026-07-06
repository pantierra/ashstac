defmodule AshStac.Item do
  @moduledoc """
  STAC Item document.
  """

  alias AshStac.{Asset, Document, Link}

  @known_fields [
    "type",
    "stac_version",
    "stac_extensions",
    "id",
    "geometry",
    "bbox",
    "properties",
    "links",
    "assets",
    "collection"
  ]

  @required_fields ["type", "stac_version", "id", "geometry", "properties", "links", "assets"]

  @enforce_keys [:type, :stac_version, :id, :geometry, :bbox, :properties, :links, :assets]
  defstruct [
    :type,
    :stac_version,
    :id,
    :geometry,
    :bbox,
    :properties,
    :collection,
    stac_extensions: [],
    links: [],
    assets: %{},
    extra: %{}
  ]

  @type t :: %__MODULE__{
          type: String.t(),
          stac_version: String.t(),
          stac_extensions: [String.t()],
          id: String.t(),
          geometry: map() | nil,
          bbox: [number()] | nil,
          properties: map(),
          links: [Link.t()],
          assets: %{optional(String.t()) => Asset.t()},
          collection: String.t() | nil,
          extra: map()
        }

  @spec new(t() | map()) :: {:ok, t()} | {:error, term()}
  def new(%__MODULE__{} = item), do: {:ok, item}

  def new(map) when is_map(map) do
    with :ok <- validate(map),
         {:ok, links} <- decode_links(map["links"]),
         {:ok, assets} <- decode_assets(map["assets"]) do
      {known, extra} = Document.split_known(map, @known_fields)

      {:ok,
       %__MODULE__{
         type: known["type"],
         stac_version: known["stac_version"],
         stac_extensions: known["stac_extensions"] || [],
         id: known["id"],
         geometry: known["geometry"],
         bbox: known["bbox"],
         properties: known["properties"],
         links: links,
         assets: assets,
         collection: known["collection"],
         extra: extra
       }}
    end
  end

  @spec collection_id(t()) :: {:ok, String.t()} | {:error, term()}
  def collection_id(%__MODULE__{collection: collection})
      when is_binary(collection) and collection != "" do
    {:ok, collection}
  end

  def collection_id(%__MODULE__{}), do: {:error, {:missing_field, "collection"}}

  @spec from_json(String.t()) :: {:ok, t()} | {:error, term()}
  def from_json(json), do: Document.from_json(json, __MODULE__)

  @spec to_json(t()) :: {:ok, String.t()} | {:error, term()}
  def to_json(%__MODULE__{} = item), do: Document.to_json(__MODULE__, item)

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = item) do
    %{
      "type" => item.type,
      "stac_version" => item.stac_version,
      "stac_extensions" => item.stac_extensions,
      "id" => item.id,
      "bbox" => item.bbox,
      "properties" => item.properties,
      "links" => Enum.map(item.links, &Link.to_map/1),
      "assets" => Map.new(item.assets, fn {key, asset} -> {key, Asset.to_map(asset)} end),
      "collection" => item.collection
    }
    |> Document.put_known(item.extra)
    |> Map.put("geometry", item.geometry)
  end

  defp validate(map) do
    Document.collect_errors([
      Document.require_fields(map, @required_fields),
      type_valid?(map),
      Document.require_string(map, "stac_version"),
      Document.require_string(map, "id"),
      geometry_valid?(map),
      bbox_valid?(map),
      Document.require_map(map, "properties"),
      datetime_present?(map),
      Document.require_list(map, "links"),
      Document.require_map(map, "assets")
    ])
  end

  defp type_valid?(%{"type" => "Feature"}), do: :ok
  defp type_valid?(%{"type" => type}), do: {:error, {:invalid_field, "type", type}}
  defp type_valid?(_map), do: {:error, {:missing_field, "type"}}

  defp geometry_valid?(%{"geometry" => nil}), do: :ok
  defp geometry_valid?(%{"geometry" => geometry}) when is_map(geometry), do: :ok

  defp geometry_valid?(%{"geometry" => geometry}),
    do: {:error, {:invalid_field, "geometry", geometry}}

  defp geometry_valid?(_map), do: {:error, {:missing_field, "geometry"}}

  defp bbox_valid?(%{"geometry" => nil, "bbox" => bbox}) when is_list(bbox), do: :ok
  defp bbox_valid?(%{"geometry" => nil}), do: :ok
  defp bbox_valid?(%{"bbox" => bbox}) when is_list(bbox), do: :ok
  defp bbox_valid?(%{"bbox" => bbox}), do: {:error, {:invalid_field, "bbox", bbox}}
  defp bbox_valid?(_map), do: {:error, {:missing_field, "bbox"}}

  defp datetime_present?(%{"properties" => properties}) when is_map(properties) do
    if Map.has_key?(properties, "datetime") do
      :ok
    else
      {:error, {:missing_field, "properties.datetime"}}
    end
  end

  defp datetime_present?(_map), do: :ok

  defp decode_links(links) do
    links
    |> Enum.reduce_while({:ok, []}, fn link, {:ok, acc} ->
      case Link.new(link) do
        {:ok, link} -> {:cont, {:ok, [link | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, links} -> {:ok, Enum.reverse(links)}
      error -> error
    end
  end

  defp decode_assets(assets) when is_map(assets) do
    assets
    |> Enum.reduce_while({:ok, %{}}, fn {key, asset}, {:ok, acc} ->
      case Asset.new(asset) do
        {:ok, asset} -> {:cont, {:ok, Map.put(acc, key, asset)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp decode_assets(assets), do: {:error, {:invalid_field, "assets", assets}}
end
