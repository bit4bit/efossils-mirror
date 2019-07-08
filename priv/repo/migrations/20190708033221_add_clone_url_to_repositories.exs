defmodule Efossils.Repo.Migrations.AddCloneUrlToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :clone_url, :string
    end
  end
end
