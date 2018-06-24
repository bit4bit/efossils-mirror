defmodule Efossils.Coherence.User do
  @moduledoc false
  use Ecto.Schema
  use Coherence.Schema

  

  schema "users" do
    field :name, :string
    field :email, :string
    coherence_schema()

    field :lower_name, :string
    field :keep_email_private, :boolean
    field :location, :string
    field :website, :string
    field :max_repo_creation, :integer, default: -1
    field :prohibit_login, :boolean, default: false
    field :avatar, :binary
    field :avatar_email, :string
    field :use_custom_avatar, :boolean, default: false
    
    #counters
    field :num_stars, :integer
    field :num_repos, :integer
    
    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email] ++ coherence_fields() ++ [:lower_name, :keep_email_private, :location, :website, :max_repo_creation, :prohibit_login, :avatar_email, :avatar, :use_custom_avatar, :num_repos, :num_stars])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end

  def changeset(model, params, :password) do
    model
    |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> validate_coherence_password_reset(params)
  end
end
