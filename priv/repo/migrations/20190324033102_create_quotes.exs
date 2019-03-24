defmodule EctoDiff.Repo.Migrations.CreateQuotes do
  use Ecto.Migration

  def change do
    alter table(:pets) do
      add :quotes, :map, default: "[]"
    end
  end
end
