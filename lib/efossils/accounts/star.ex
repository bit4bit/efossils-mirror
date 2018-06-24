defmodule Efossils.Accounts.Star do
  use Ecto.Schema
  import Ecto.Changeset


  schema "stars" do
    field :user_id, :integer
    field :repository_id, :integer

    timestamps()
  end

  @doc false
  def changeset(star, attrs) do
    star
    |> cast(attrs, [])
    |> validate_required([])
  end
end
