defmodule EctoDiff.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_diff,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end

  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.10", only: :test},
      {:jason, ">= 1.0.0", only: [:dev, :test]},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]}
    ]
  end
end
