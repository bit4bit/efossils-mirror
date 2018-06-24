defmodule Efossils.Accounts.Collaboration do
  use Ecto.Schema
  import Ecto.Changeset


  schema "collaborations" do
    field :capabilities, :string
    field :fossil_password, :string
    field :fossil_username, :string

    belongs_to :repository, Efossils.Accounts.Repository
    belongs_to :user, Efossils.Coherence.User

    timestamps()
  end

  @doc false
  def changeset(collaboration, attrs) do
    collaboration
    |> cast(attrs, [:capabilities, :fossil_username, :fossil_password, :user_id, :repository_id])
    |> validate_required([:capabilities, :fossil_username, :fossil_password])
  end
end
