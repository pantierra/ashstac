defmodule AshStac.Pgstac.Contract do
  @moduledoc """
  Compatibility checks and documented assumptions for pgSTAC.

  pgSTAC owns its schema and search behavior. This module keeps the boundary
  explicit so the rest of the library can stay small.
  """

  @supported_pgstac_requirement Version.parse_requirement!(">= 0.9.0 and < 0.10.0")
  @supported_postgres_requirement Version.parse_requirement!(">= 13.0.0")

  @type check :: {:ok, map()} | {:error, term()}

  @doc """
  Returns the pgSTAC version range this library is designed around.
  """
  @spec supported_pgstac_requirement() :: Version.Requirement.t()
  def supported_pgstac_requirement, do: @supported_pgstac_requirement

  @doc """
  Returns the PostgreSQL version range expected by the pgSTAC-backed adapter.
  """
  @spec supported_postgres_requirement() :: Version.Requirement.t()
  def supported_postgres_requirement, do: @supported_postgres_requirement

  @doc """
  Checks the connected database for pgSTAC and PostgreSQL compatibility.

  Accepts a Postgrex connection process or module implementing `query/3`.
  """
  @spec check(pid() | module()) :: check()
  def check(conn) do
    with {:ok, postgres_version} <- postgres_version(conn),
         :ok <- require_version(:postgres, postgres_version, @supported_postgres_requirement),
         {:ok, pgstac_version} <- pgstac_version(conn),
         :ok <- require_version(:pgstac, pgstac_version, @supported_pgstac_requirement) do
      {:ok, %{postgres: postgres_version, pgstac: pgstac_version}}
    end
  end

  @doc """
  Fetches the PostgreSQL server version as a `Version`.
  """
  @spec postgres_version(pid() | module()) :: {:ok, Version.t()} | {:error, term()}
  def postgres_version(conn) do
    case query(conn, "SHOW server_version", []) do
      {:ok, %{rows: [[version_string]]}} -> parse_version(version_string)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Fetches the installed pgSTAC version.
  """
  @spec pgstac_version(pid() | module()) :: {:ok, Version.t()} | {:error, term()}
  def pgstac_version(conn) do
    case query(conn, "SELECT pgstac.get_version()", []) do
      {:ok, %{rows: [[version_string]]}} -> parse_version(version_string)
      {:error, reason} -> {:error, {:pgstac_version_unavailable, reason}}
    end
  end

  defp require_version(name, version, requirement) do
    if Version.match?(version, requirement) do
      :ok
    else
      {:error, {:unsupported_version, name, version, requirement}}
    end
  end

  defp parse_version(version) when is_binary(version) do
    version
    |> version_number()
    |> normalize_version()
    |> Version.parse()
    |> case do
      {:ok, parsed} -> {:ok, parsed}
      :error -> {:error, {:invalid_version, version}}
    end
  end

  defp version_number(version) do
    case Regex.run(~r/\d+(?:\.\d+){0,2}/, version) do
      [number] -> number
      nil -> version
    end
  end

  defp normalize_version(version) do
    parts = String.split(version, ".")

    case parts do
      [_major] -> version <> ".0.0"
      [_major, _minor] -> version <> ".0"
      _parts -> version
    end
  end

  defp query(conn, sql, params) when is_pid(conn), do: Postgrex.query(conn, sql, params)
  defp query(conn, sql, params) when is_atom(conn), do: conn.query(sql, params)
end
