defmodule EctoDiff.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    create table(:resources) do
      add :pet_id, references(:pets)
      add :refid, :uuid
    end

    create table(:toys) do
      add :name, :string
      add :type, :string
      add :quantity, :integer, default: 1
      add :resource_id, references(:resources)
      add :refid, :uuid
    end
  end
end
