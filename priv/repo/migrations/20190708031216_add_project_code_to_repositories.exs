defmodule Efossils.Repo.Migrations.AddProjectCodeToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :project_code, :string
    end
  end
end
