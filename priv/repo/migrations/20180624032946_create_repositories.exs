defmodule Efossils.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
    create table(:repositories) do
      add :lower_name, :string
      add :name, :string
      add :description, :string
      add :website, :string
      add :num_watchers, :integer
      add :num_stars, :integer
      add :num_forks, :integer
      add :is_private, :boolean, default: false, null: false
      add :size, :integer
      add :base_repository_id, references(:repositories, on_delete: :nothing)
      add :owner_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    
    create unique_index(:repositories, [:owner_id, :name])
    
    create index(:repositories, [:base_repository_id])
    create index(:repositories, [:owner_id])
  end
end
