defmodule Efossils.Repo.Migrations.AddCoherenceToUser do
  use Ecto.Migration
  def change do
    alter table(:users) do
      # confirmable
      add :confirmation_token, :string
      add :confirmed_at, :utc_datetime
      add :confirmation_sent_at, :utc_datetime
    end


  end
end
