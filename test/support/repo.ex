defmodule EctoDiff.Repo do
  use Ecto.Repo,
    otp_app: :ecto_diff,
    adapter: Ecto.Adapters.Postgres

  def init(_type, config) do
    case System.get_env("DATABASE_URL") do
      nil -> {:ok, config}
      url -> {:ok, Keyword.put(config, :url, url)}
    end
  end
end
