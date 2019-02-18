defmodule Efossils.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :url, :string
      add :type, :string
      add :content, :map
      add :rest, :map
      add :seen, :boolean, default: false, null: false

      timestamps()
    end

  end
end
