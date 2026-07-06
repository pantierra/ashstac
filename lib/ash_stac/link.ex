defmodule AshStac.Link do
  @moduledoc """
  STAC Link object.
  """

  alias AshStac.Document

  @known_fields ["href", "rel", "type", "title", "method", "headers", "body", "merge"]

  @enforce_keys [:href, :rel]
  defstruct [:href, :rel, :type, :title, :method, :headers, :body, :merge, extra: %{}]

  @type t :: %__MODULE__{
          href: String.t(),
          rel: String.t(),
          type: String.t() | nil,
          title: String.t() | nil,
          method: String.t() | nil,
          headers: map() | nil,
          body: term(),
          merge: boolean() | nil,
          extra: map()
        }

  @spec new(t() | map()) :: {:ok, t()} | {:error, term()}
  def new(%__MODULE__{} = link), do: {:ok, link}

  def new(map) when is_map(map) do
    with :ok <- validate(map) do
      {known, extra} = Document.split_known(map, @known_fields)

      {:ok,
       %__MODULE__{
         href: known["href"],
         rel: known["rel"],
         type: known["type"],
         title: known["title"],
         method: known["method"],
         headers: known["headers"],
         body: known["body"],
         merge: known["merge"],
         extra: extra
       }}
    end
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = link) do
    %{
      "href" => link.href,
      "rel" => link.rel,
      "type" => link.type,
      "title" => link.title,
      "method" => link.method,
      "headers" => link.headers,
      "body" => link.body,
      "merge" => link.merge
    }
    |> Document.put_known(link.extra)
  end

  defp validate(map) do
    Document.collect_errors([
      Document.require_string(map, "href"),
      Document.require_string(map, "rel")
    ])
  end
end
