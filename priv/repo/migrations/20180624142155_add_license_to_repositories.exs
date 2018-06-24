defmodule Efossils.Repo.Migrations.AddLicenseToRepositories do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      add :license, :string
    end
  end
end
