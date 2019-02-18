defmodule Efossils.ActivityPub.Follow do
  use Ecto.Schema
  import Ecto.Changeset


  schema "follows" do
    field :actor, :map
    field :banned, :boolean, default: false
    field :seen, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:actor, :banned, :seen])
    |> validate_required([:actor])
  end
end
