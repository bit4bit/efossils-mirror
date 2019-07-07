defmodule Efossils.Repo.Migrations.CreatePushMirrors do
  use Ecto.Migration

  def change do
    create table(:push_mirrors) do
      add :source, :string
      add :name, :string
      add :url, :string
      add :repository_id, references(:repositories, on_delete: :nothing)

      timestamps()
    end

    create index(:push_mirrors, [:repository_id])
  end
end
