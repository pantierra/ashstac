defmodule AshStac.Document do
  @moduledoc false

  @type error :: {:missing_field, String.t()} | {:invalid_field, String.t(), term()}

  @spec from_json(String.t(), module()) :: {:ok, struct()} | {:error, term()}
  def from_json(json, module) when is_binary(json) do
    with {:ok, map} <- Jason.decode(json) do
      module.new(map)
    end
  end

  @spec to_json(module(), struct()) :: {:ok, String.t()} | {:error, term()}
  def to_json(module, struct), do: Jason.encode(module.to_map(struct))

  @spec require_fields(map(), [String.t()]) :: :ok | {:error, [error()]}
  def require_fields(map, fields) do
    errors =
      fields
      |> Enum.reject(&Map.has_key?(map, &1))
      |> Enum.map(&{:missing_field, &1})

    if errors == [], do: :ok, else: {:error, errors}
  end

  @spec require_string(map(), String.t()) :: :ok | {:error, error()}
  def require_string(map, field) do
    case Map.fetch(map, field) do
      {:ok, value} when is_binary(value) and value != "" -> :ok
      {:ok, value} -> {:error, {:invalid_field, field, value}}
      :error -> {:error, {:missing_field, field}}
    end
  end

  @spec require_map(map(), String.t()) :: :ok | {:error, error()}
  def require_map(map, field) do
    case Map.fetch(map, field) do
      {:ok, value} when is_map(value) -> :ok
      {:ok, value} -> {:error, {:invalid_field, field, value}}
      :error -> {:error, {:missing_field, field}}
    end
  end

  @spec require_list(map(), String.t()) :: :ok | {:error, error()}
  def require_list(map, field) do
    case Map.fetch(map, field) do
      {:ok, value} when is_list(value) -> :ok
      {:ok, value} -> {:error, {:invalid_field, field, value}}
      :error -> {:error, {:missing_field, field}}
    end
  end

  @spec split_known(map(), [String.t()]) :: {map(), map()}
  def split_known(map, known_fields) do
    Map.split(map, known_fields)
  end

  @spec put_known(map(), map()) :: map()
  def put_known(known, extra) do
    known
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
    |> Map.merge(extra)
  end

  @spec collect_errors([:ok | {:error, term()}]) :: :ok | {:error, [term()]}
  def collect_errors(results) do
    errors =
      results
      |> Enum.flat_map(fn
        :ok -> []
        {:error, errors} when is_list(errors) -> errors
        {:error, error} -> [error]
      end)

    if errors == [], do: :ok, else: {:error, errors}
  end
end
