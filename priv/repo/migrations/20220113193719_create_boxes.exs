defmodule InventoryCore.Repo.Migrations.CreateBoxes do
  use Ecto.Migration

  def change do
    create table(:boxes) do
      add :shapes, {:array, :map}, default: []
    end
  end
end
