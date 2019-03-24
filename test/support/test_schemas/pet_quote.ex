defmodule EctoDiff.PetQuote do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :quote, :string
  end

  def changeset(struct, params), do: cast(struct, params, [:quote])
end
