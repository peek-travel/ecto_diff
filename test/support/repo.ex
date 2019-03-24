defmodule EctoDiff.Repo do
  use Ecto.Repo,
    otp_app: :ecto_diff,
    adapter: Ecto.Adapters.Postgres
end
