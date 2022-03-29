import Config

config :ecto_diff, ecto_repos: [EctoDiff.Repo]

config :ecto_diff, EctoDiff.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  url: "ecto://postgres@localhost/ecto_diff_test"

config :logger, level: :info
