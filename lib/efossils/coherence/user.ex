# Efossils -- a multirepository for fossil-scm
# Copyright (C) 2018  Jovany Leandro G.C <bit4bit@riseup.net>
#
# This file is part of Efossils.
#
# Efossils is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Efossils is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

    has_many :repositories, Efossils.Accounts.Repository, [foreign_key: :owner_id]
    has_many :stars, Efossils.Accounts.Star

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email] ++ coherence_fields() ++ [:lower_name, :keep_email_private, :location, :website, :max_repo_creation, :prohibit_login, :avatar_email, :avatar, :use_custom_avatar, :num_repos, :num_stars])
    |> Efossils.Utils.build_lower_name()
    |> validate_required([:lower_name, :name, :email])
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
