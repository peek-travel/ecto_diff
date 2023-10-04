defmodule EctoDiff.Resource do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema("resources") do
    belongs_to :pet, EctoDiff.Pet
    has_many :toys, EctoDiff.Toy, on_replace: :delete

    field :refid, Ecto.UUID, autogenerate: true
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:pet_id])
    |> cast_assoc(:toys)
  end
end
