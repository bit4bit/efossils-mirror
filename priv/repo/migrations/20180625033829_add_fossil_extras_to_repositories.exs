defmodule Efossils.Repo.Migrations.AddFossilExtrasToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :fossil_extras, :map
    end
  end
end
