defmodule Efossils.Repo.Migrations.CreateStars do
  use Ecto.Migration

  def change do
    create table(:stars) do
      add :user_id, references(:users, on_delete: :nothing)
      add :repository_id, references(:repositories, on_delete: :nothing)

      timestamps()
    end

    create index(:stars, [:user_id])
    create index(:stars, [:repository_id])
  end
end
