defmodule AshStac do
  @moduledoc """
  Small Elixir helpers for STAC documents backed by pgSTAC.

  `AshStac` keeps three responsibilities separate:

  * typed STAC document structs with JSON round-trip safety
  * a thin pgSTAC adapter boundary
  * optional Ash-facing resources for host applications
  """

  alias AshStac.{Collection, Item, Pgstac, SearchQuery}

  @doc """
  Decodes and validates a STAC Collection.
  """
  @spec collection(map() | Collection.t()) :: {:ok, Collection.t()} | {:error, term()}
  def collection(document), do: Collection.new(document)

  @doc """
  Decodes and validates a STAC Item.
  """
  @spec item(map() | Item.t()) :: {:ok, Item.t()} | {:error, term()}
  def item(document), do: Item.new(document)

  @doc """
  Builds a structured STAC item-search body.
  """
  @spec search_query(map() | SearchQuery.t()) :: {:ok, SearchQuery.t()} | {:error, term()}
  def search_query(document), do: SearchQuery.new(document)

  @doc """
  Returns the pgSTAC adapter module.
  """
  @spec pgstac() :: module()
  def pgstac, do: Pgstac
end
