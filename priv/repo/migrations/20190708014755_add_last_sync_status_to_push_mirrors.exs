defmodule Efossils.Repo.Migrations.AddLastSyncStatusToPushMirrors do
  use Ecto.Migration

  def change do
    alter table(:push_mirrors) do
      add :last_sync_status, :string
    end
  end
end
