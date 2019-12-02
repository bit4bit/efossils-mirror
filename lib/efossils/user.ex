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

defmodule Efossils.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  use Pow.Ecto.Schema,
    password_hash_methods: {&Comeonin.Bcrypt.hashpwsalt/1,
                            &Comeonin.Bcrypt.checkpw/2}
  use Pow.Extension.Ecto.Schema,
    extensions: [PowEmailConfirmation, PowResetPassword]
  
  schema "users" do
    field :name, :string

    field :username, :string
    # username saneado
    field :nickname, :string
    field :keep_email_private, :boolean
    field :location, :string
    field :website, :string
    field :max_repo_creation, :integer, default: -1
    field :prohibit_login, :boolean, default: false
    field :avatar, :binary
    field :avatar_email, :string
    field :use_custom_avatar, :boolean, default: false
    field :color_css, :string

    #counters
    field :num_stars, :integer, default: 0
    field :num_repos, :integer, default: 0

    has_many :repositories, Efossils.Accounts.Repository, [foreign_key: :owner_id]
    has_many :stars, Efossils.Accounts.Star
    
    pow_user_fields()
    
    timestamps()
  end

  def changeset_profile(model, params \\ %{}) do
    model
    |> cast(params, [:name, :nickname, :email, :keep_email_private, :location, :website, :avatar_email, :avatar, :use_custom_avatar, :password, :confirm_password])
    |> Efossils.Utils.build_nickname()
    |> put_color()
    |> validate_required([:nickname, :name, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> pow_changeset(params)
    |> pow_extension_changeset(params)
  end
  
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :username, :email, :keep_email_private, :location, :website, :max_repo_creation, :prohibit_login, :avatar_email, :avatar, :use_custom_avatar, :num_repos, :num_stars])
    |> Efossils.Utils.build_nickname()
    |> put_name()
    |> put_color()
    |> validate_required([:username, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> pow_changeset(params)
    |> pow_extension_changeset(params)
  end
  
  def changeset(model, params, :password) do
    model
    |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> pow_changeset(params)
    |> pow_extension_changeset(params)
  end

  defp put_name(changeset) do
    name = case fetch_field(changeset, :name) do
             {_, name} -> name
             _ -> nil
           end
    username = case fetch_field(changeset, :username) do
                 {_, username} -> username
                 _ -> nil
               end
    if name == nil and username != nil do
      put_change(changeset, :name, Efossils.Utils.sanitize_name(username))
    else
      changeset
    end
  end

  defp put_color(changeset) do
    colors = [
      "red", "orange", "yellow", "olive", "green", "teal", "blue", "violet", "purple",
      "pink", "brown", "grey", "black"
    ]
    changeset
    |> put_change(:color_css, Enum.random(colors))
  end
end
