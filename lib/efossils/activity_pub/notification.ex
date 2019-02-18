defmodule Efossils.ActivityPub.Notification do
  use Ecto.Schema
  import Ecto.Changeset


  schema "notifications" do
    field :url, :string
    field :content, :map
    field :seen, :boolean, default: false
    field :type, :string

    timestamps()
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:type, :content, :seen, :url])
    |> validate_required([:type, :content, :url])
  end
end
