defmodule Efossils.Repo.Migrations.AddMirrorToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :is_mirror, :boolean
    end
  end
end
