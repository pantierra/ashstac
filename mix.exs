defmodule AshStac.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_stac,
      version: "0.1.0",
      elixir: "~> 1.20",
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
      links: %{}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE", "guides/pgstac_contract.md"]
    ]
  end
end
