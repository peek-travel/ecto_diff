defmodule EctoDiff.Toy do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema("toys") do
    belongs_to :resource, EctoDiff.Resource, type: :id

    field :name, :string
    field :type, :string
    field :quantity, :integer, default: 1
  end

  def changeset(toy, params) do
    toy |> cast(params, [:name, :type, :quantity, :resource_id])
  end
end
