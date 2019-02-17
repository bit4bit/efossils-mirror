defmodule Efossils.Repo.Migrations.RenameColumnLowerNameToNickameToUser do
  use Ecto.Migration

  def change do
    rename table(:users), :lower_name, to: :nickname
  end
end
