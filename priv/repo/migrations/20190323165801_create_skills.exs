defmodule EctoDiff.Repo.Migrations.CreateSkills do
  use Ecto.Migration

  def change do
    create table(:skills) do
      add :name, :string
      add :level, :integer
      add :refid, :uuid
      add :pet_id, references(:pets)
    end
  end
end
