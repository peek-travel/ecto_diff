defmodule EctoDiff.MixProject do
  use Mix.Project

  @version "0.5.0"
  @source_url "https://github.com/peek-travel/ecto_diff"

  def project do
    [
      app: :ecto_diff,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      dialyzer: dialyzer(),
      docs: docs(),
      description: description(),
      package: package(),
      aliases: aliases()
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
      plt_file: {:no_warn, "plts/ecto_diff.plt"},
      flags: [:error_handling, :underspecs]
    ]
  end

  defp docs do
    [
      main: "EctoDiff",
      source_ref: @version,
      source_url: @source_url,
      main: ["readme"],
      extras: ["README.md", "CHANGELOG.md", "LICENSE.md"]
    ]
  end

  defp description do
    """
    Generates a data structure describing the difference between two ecto structs
    """
  end

  defp package do
    [
      files: ["lib", ".formatter.exs", "mix.exs", "README.md", "LICENSE.md", "CHANGELOG.md"],
      maintainers: ["Peek Travel <noreply@peek.com>"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Readme" => "#{@source_url}/blob/#{@version}/README.md",
        "Changelog" => "#{@source_url}/blob/#{@version}/CHANGELOG.md"
      }
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.8", only: [:dev, :test]},
      {:ecto, "~> 3.10.3"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:jason, ">= 1.0.0", only: [:dev, :test]},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
