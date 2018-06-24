defmodule Efossils.Accounts.Repository do
  use Ecto.Schema
  import Ecto.Changeset


  schema "repositories" do
    field :description, :string
    field :is_private, :boolean, default: false
    field :lowerName, :string
    field :name, :string
    field :num_forks, :integer
    field :num_stars, :integer
    field :num_watchers, :integer
    field :size, :integer
    field :website, :string
    belongs_to :base_repository_id, Efossils.Accounts.Repository
    belongs_to :owner, Efossils.Coherence.User

    timestamps()
  end

  @doc false
  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:lowerName, :name, :description, :website, :num_watchers, :num_stars, :num_forks, :is_private, :size, :owner_id, :base_repository_id])
    |> cast_assoc([:owner, :base_repository])
    |> validate_required([:lowerName, :name, :description, :website, :num_watchers, :num_stars, :num_forks, :is_private, :size])
  end
end
