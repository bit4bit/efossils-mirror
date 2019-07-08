defmodule Efossils.Repo.Migrations.CreateFollows do
  use Ecto.Migration

  def change do
    create table(:follows) do
      add :ap_id, :string
      add :banned, :boolean, default: false, null: false

      timestamps()
    end

  end
end
