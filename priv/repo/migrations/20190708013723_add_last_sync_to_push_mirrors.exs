defmodule Efossils.Repo.Migrations.AddLastSyncToPushMirrors do
  use Ecto.Migration

  def change do
    alter table(:push_mirrors) do
      add :last_sync, :naive_datetime
    end
  end
end
