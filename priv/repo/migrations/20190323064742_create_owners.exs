defmodule EctoDiff.Repo.Migrations.CreateOwners do
  use Ecto.Migration

  def change do
    create table(:owners) do
      add :name, :string
      add :refid, :uuid
    end

    alter table(:pets) do
      add :owner_id, references(:owners)
    end
  end
end
