defmodule Efossils.Repo.Migrations.AddExtraAttributesToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :lower_name, :string
      add :keep_email_private, :boolean
      add :location, :string
      add :website, :string
      add :max_repo_creation, :integer, default: 19 #1983
      add :prohibit_login, :boolean, default: false
      add :avatar, :binary
      add :avatar_email, :string
      add :use_custom_avatar, :boolean, default: false

      add :num_stars, :integer, default: 0
      add :num_repos, :integer, default: 0
    end
  end
end
