defmodule EctoDiff.Repo.Migrations.CreateDetails do
  use Ecto.Migration

  def change do
    alter table(:pets) do
      add :details, :map
    end
  end
end
