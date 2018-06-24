defmodule Efossils.Repo.Migrations.CreateCollaborations do
  use Ecto.Migration

  def change do
    create table(:collaborations) do
      add :capabilities, :string
      add :fossil_username, :string
      add :fossil_password, :string
      add :repository_id, references(:repositories, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:collaborations, [:repository_id])
    create index(:collaborations, [:user_id])
  end
end
