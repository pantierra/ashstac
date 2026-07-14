defmodule AshStac.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_stac,
      version: "0.0.2",
      elixir: "~> 1.20",
      description: description(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [check: :test]
    ]
  end

  defp deps do
    [
      {:ash, "~> 3.29.3"},
      {:credo, "~> 1.7.19", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.4"},
      {:postgrex, "~> 0.22.2"}
    ]
  end

  defp aliases do
    [
      check: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo --strict",
        "test"
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/pantierra/ashstac",
        "pgSTAC" => "https://github.com/stac-utils/pgstac"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/pantierra/ashstac",
      extras: ["README.md", "LICENSE", "guides/pgstac_contract.md"]
    ]
  end

  defp description do
    "Small Elixir helpers for STAC documents backed by pgSTAC."
  end
end
