defmodule Efossils.ActivityPub.Follow do
  use Ecto.Schema
  import Ecto.Changeset


  schema "follows" do
    field :ap_id, :string
    field :banned, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(follow, attrs) do
    follow
    |> cast(attrs, [:ap_id, :banned])
    |> validate_required([:ap_id, :banned])
  end
end
