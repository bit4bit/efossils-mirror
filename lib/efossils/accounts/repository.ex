defmodule Efossils.Accounts.Repository do
  use Ecto.Schema
  import Ecto.Changeset

  @licenses ["AGPL-3.0": "agpl3"]
  def licenses, do: @licenses
  
  schema "repositories" do
    field :description, :string
    field :is_private, :boolean, default: false
    field :lower_name, :string
    field :name, :string
    field :num_forks, :integer
    field :num_stars, :integer
    field :num_watchers, :integer
    field :size, :integer
    field :website, :string
    field :license, :string
    field :fossil_extras, :map
    belongs_to :base_repository, Efossils.Accounts.Repository
    belongs_to :owner, Efossils.Coherence.User
    has_many :collaborations, Efossils.Accounts.Collaboration
    has_many :collaborations_users,  through: [:collaborations, :user]
    timestamps()
  end

  @doc false
  def changeset(repository, attrs) do
    repository
    |> cast(attrs, [:lower_name, :name, :description, :website, :num_watchers, :num_stars, :num_forks, :is_private, :size, :license, :owner_id, :fossil_extras])
    |> Efossils.Utils.build_lower_name()
    |> cast_assoc(:owner)
    |> cast_assoc(:base_repository)
    |> validate_required([:name, :is_private])
    |> unique_constraint(:name, name: :repositories_owner_id_name_index)
  end

  @doc false
  def prepare_attrs(attrs) do
    attrs
    |> Map.put("lower_name", String.downcase(attrs["name"]))
  end

end
