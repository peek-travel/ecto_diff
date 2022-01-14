defmodule EctoDiff.Shape do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :angles, :integer
  end

  def changeset(struct, params), do: cast(struct, params, [:angles])
end
