defmodule EctoDiff.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_diff,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0", only: [:dev, :test]},
      {:jason, ">= 1.0.0"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
