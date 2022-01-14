defmodule EctoDiff.Box do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema("boxes") do
    embeds_many :shapes, EctoDiff.Shape, on_replace: :delete
  end

  def new(params), do: changeset(%__MODULE__{}, params)
  def update(struct, params), do: changeset(struct, params)

  defp changeset(struct, params) do
    struct
    |> cast(params, [])
    |> cast_embed(:shapes)
  end
end
