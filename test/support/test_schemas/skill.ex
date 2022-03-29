defmodule EctoDiff.Skill do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema("skills") do
    field :name, :string
    field :level, :integer, default: 1
    field :refid, Ecto.UUID, autogenerate: true

    belongs_to :pet, EctoDiff.Pet
  end

  def changeset(struct, params), do: cast(struct, params, [:name, :level])
end
