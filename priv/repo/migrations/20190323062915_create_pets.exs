defmodule EctoDiff.Repo.Migrations.CreatePets do
  use Ecto.Migration

  def change do
    create table(:pets) do
      add :name, :string
      add :type, :string
      add :refid, :uuid
    end
  end
end
