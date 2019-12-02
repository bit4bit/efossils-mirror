defmodule Efossils.Repo.Migrations.AddColorToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :color_css, :string, default: "white"
    end
  end
end
