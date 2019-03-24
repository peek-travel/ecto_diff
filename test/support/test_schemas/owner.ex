defmodule EctoDiff.Owner do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema("owners") do
    field :name, :string
  end

  def changeset(struct, params), do: cast(struct, params, [:name])
end
