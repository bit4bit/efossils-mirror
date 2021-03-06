defmodule Efossils.Repositories.PushMirror do
  use Ecto.Schema
  import Ecto.Changeset


  schema "push_mirrors" do
    field :source, :string
    field :name, :string
    field :url, :string
    field :last_sync, :naive_datetime
    field :last_sync_status, :string
    belongs_to :repository, Efossils.Accounts.Repository
    timestamps()
  end

  @doc false
  def changeset(push_mirror, attrs) do
    push_mirror
    |> cast(attrs, [:name, :source, :url, :last_sync_status, :last_sync, :repository_id])
    |> validate_required([:name, :source, :url])
  end
end
