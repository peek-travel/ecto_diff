defmodule EctoDiff.PetDetails do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :description, :string
  end

  def changeset(struct, params), do: cast(struct, params, [:description])
end
