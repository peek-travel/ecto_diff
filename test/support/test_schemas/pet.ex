defmodule EctoDiff.Pet do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema("pets") do
    belongs_to :owner, EctoDiff.Owner, on_replace: :update
    has_many :skills, EctoDiff.Skill, on_replace: :delete
    has_many :resources, EctoDiff.Resource, on_replace: :delete
    has_many :toys, through: [:resources, :toys], on_replace: :update
    embeds_one :details, EctoDiff.PetDetails, on_replace: :update
    embeds_many :quotes, EctoDiff.PetQuote, on_replace: :delete
    field :name, :string
    field :type, :string, default: "Cat"
    field :refid, Ecto.UUID, autogenerate: true
    field :owner_email, :string, virtual: true
  end

  def new(params), do: changeset(%__MODULE__{}, params)
  def update(struct, params), do: changeset(struct, params)

  defp changeset(struct, params) do
    struct
    |> cast(params, [:name, :type])
    |> cast_assoc(:owner)
    |> cast_assoc(:skills)
    |> cast_assoc(:resources)
    |> cast_embed(:details)
    |> cast_embed(:quotes)
  end
end
