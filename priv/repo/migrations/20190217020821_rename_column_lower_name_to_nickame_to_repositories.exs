defmodule Efossils.Repo.Migrations.RenameColumnLowerNameToNickameToRepositories do
  use Ecto.Migration

  def change do
    rename table(:repositories), :lower_name, to: :nickname
  end
end
