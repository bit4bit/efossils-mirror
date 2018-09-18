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

defmodule Efossils.Accounts.Collaboration do
  @moduledoc false

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
    |> unique_constraint(:repository_id, name: :collaborations_repository_id_user_id_index)
  end
end
