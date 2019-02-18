defmodule Efossils.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create table(:follows) do
      add :actor, :map
      add :banned, :boolean, default: false, null: false
      add :seen, :boolean, default: false, null: false

      timestamps()
    end

  end
end
