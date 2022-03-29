defmodule EctoDiff.Owner do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema("owners") do
    field :name, :string
    field :refid, Ecto.UUID, autogenerate: true
  end

  def changeset(struct, params), do: cast(struct, params, [:name])
end
