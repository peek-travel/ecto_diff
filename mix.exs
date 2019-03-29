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
      preferred_cli_env: preferred_cli_env(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.json": :test
    ]
  end

  defp dialyzer do
    [
      plt_apps: [:compiler, :ecto, :elixir, :kernel, :stdlib],
      plt_file: {:no_warn, "priv/plts/ecto_diff.plt"},
      flags: [:error_handling, :underspecs]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.10", only: :test},
      {:dialyxir, "~> 1.0.0-rc.5", only: [:dev], runtime: false},
      {:jason, ">= 1.0.0", only: [:dev, :test]},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]}
    ]
  end
end
