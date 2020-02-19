defmodule Efossils.Repo.Migrations.ModifyRepositoriesDescription do
  use Ecto.Migration

  def change do
    alter table(:repositories) do
      modify :description, :text
    end
  end
end
