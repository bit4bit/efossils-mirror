defmodule Efossils.Repo.Migrations.AddSourceToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :source, :string
    end
  end
end
