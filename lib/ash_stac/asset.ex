defmodule AshStac.Asset do
  @moduledoc """
  STAC Asset object.

  Assets stay embedded in item/collection documents. They are not database
  resources in this library.
  """

  alias AshStac.Document

  @known_fields ["href", "title", "description", "type", "roles"]

  @enforce_keys [:href]
  defstruct [:href, :title, :description, :type, roles: [], extra: %{}]

  @type t :: %__MODULE__{
          href: String.t(),
          title: String.t() | nil,
          description: String.t() | nil,
          type: String.t() | nil,
          roles: [String.t()],
          extra: map()
        }

  @spec new(t() | map()) :: {:ok, t()} | {:error, term()}
  def new(%__MODULE__{} = asset), do: {:ok, asset}

  def new(map) when is_map(map) do
    with :ok <- validate(map) do
      {known, extra} = Document.split_known(map, @known_fields)

      {:ok,
       %__MODULE__{
         href: known["href"],
         title: known["title"],
         description: known["description"],
         type: known["type"],
         roles: known["roles"] || [],
         extra: extra
       }}
    end
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = asset) do
    %{
      "href" => asset.href,
      "title" => asset.title,
      "description" => asset.description,
      "type" => asset.type,
      "roles" => asset.roles
    }
    |> Document.put_known(asset.extra)
  end

  defp validate(map) do
    Document.collect_errors([
      Document.require_string(map, "href"),
      roles_valid?(map)
    ])
  end

  defp roles_valid?(%{"roles" => roles}) when is_list(roles), do: :ok
  defp roles_valid?(%{"roles" => roles}), do: {:error, {:invalid_field, "roles", roles}}
  defp roles_valid?(_map), do: :ok
end
