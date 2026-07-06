defmodule AshStac.Collection do
  @moduledoc """
  STAC Collection document.

  Unknown extension fields are preserved in `extra` and emitted during
  serialization.
  """

  alias AshStac.{Asset, Document, Link}

  @known_fields [
    "type",
    "stac_version",
    "stac_extensions",
    "id",
    "title",
    "description",
    "keywords",
    "license",
    "providers",
    "extent",
    "summaries",
    "links",
    "assets",
    "item_assets"
  ]

  @required_fields ["stac_version", "id", "description", "license", "extent", "links"]

  @enforce_keys [:id, :description, :license, :extent, :links]
  defstruct [
    :type,
    :stac_version,
    :id,
    :title,
    :description,
    :keywords,
    :license,
    :providers,
    :extent,
    :summaries,
    :item_assets,
    stac_extensions: [],
    links: [],
    assets: %{},
    extra: %{}
  ]

  @type t :: %__MODULE__{
          type: String.t() | nil,
          stac_version: String.t(),
          stac_extensions: [String.t()],
          id: String.t(),
          title: String.t() | nil,
          description: String.t(),
          keywords: [String.t()] | nil,
          license: String.t(),
          providers: [map()] | nil,
          extent: map(),
          summaries: map() | nil,
          links: [Link.t()],
          assets: %{optional(String.t()) => Asset.t()},
          item_assets: map() | nil,
          extra: map()
        }

  @spec new(t() | map()) :: {:ok, t()} | {:error, term()}
  def new(%__MODULE__{} = collection), do: {:ok, collection}

  def new(map) when is_map(map) do
    with :ok <- validate(map),
         {:ok, links} <- decode_links(map["links"]),
         {:ok, assets} <- decode_assets(map["assets"] || %{}) do
      {known, extra} = Document.split_known(map, @known_fields)

      {:ok,
       %__MODULE__{
         type: known["type"],
         stac_version: known["stac_version"],
         stac_extensions: known["stac_extensions"] || [],
         id: known["id"],
         title: known["title"],
         description: known["description"],
         keywords: known["keywords"],
         license: known["license"],
         providers: known["providers"],
         extent: known["extent"],
         summaries: known["summaries"],
         links: links,
         assets: assets,
         item_assets: known["item_assets"],
         extra: extra
       }}
    end
  end

  @spec from_json(String.t()) :: {:ok, t()} | {:error, term()}
  def from_json(json), do: Document.from_json(json, __MODULE__)

  @spec to_json(t()) :: {:ok, String.t()} | {:error, term()}
  def to_json(%__MODULE__{} = collection), do: Document.to_json(__MODULE__, collection)

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = collection) do
    %{
      "type" => collection.type,
      "stac_version" => collection.stac_version,
      "stac_extensions" => collection.stac_extensions,
      "id" => collection.id,
      "title" => collection.title,
      "description" => collection.description,
      "keywords" => collection.keywords,
      "license" => collection.license,
      "providers" => collection.providers,
      "extent" => collection.extent,
      "summaries" => collection.summaries,
      "links" => Enum.map(collection.links, &Link.to_map/1),
      "assets" => Map.new(collection.assets, fn {key, asset} -> {key, Asset.to_map(asset)} end),
      "item_assets" => collection.item_assets
    }
    |> Document.put_known(collection.extra)
  end

  defp validate(map) do
    Document.collect_errors([
      Document.require_fields(map, @required_fields),
      Document.require_string(map, "stac_version"),
      Document.require_string(map, "id"),
      Document.require_string(map, "description"),
      Document.require_string(map, "license"),
      Document.require_map(map, "extent"),
      Document.require_list(map, "links")
    ])
  end

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
