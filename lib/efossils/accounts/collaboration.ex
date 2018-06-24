defmodule Efossils.Accounts.Collaboration do
  use Ecto.Schema
  import Ecto.Changeset


  schema "collaborations" do
    field :capabilities, :string
    field :fossil_password, :string
    field :fossil_username, :string
    field :repository, :id
    field :user, :id

    timestamps()
  end

  @doc false
  def changeset(collaboration, attrs) do
    collaboration
    |> cast(attrs, [:capabilities, :fossil_username, :fossil_password])
    |> validate_required([:capabilities, :fossil_username, :fossil_password])
  end
end
