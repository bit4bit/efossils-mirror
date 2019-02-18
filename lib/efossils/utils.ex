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

defmodule Efossils.Utils do
  @moduledoc false

  @federated_name Application.get_env(:efossils, :federated_name)

  def fossil_path(rest, user, repo) do
    "/fossil/user/#{user.nickname}/repository/#{repo.nickname}/#{rest}"
  end

  def build_nickname(changeset) do
    if username = Ecto.Changeset.get_change(changeset, :username) do
      Ecto.Changeset.put_change(changeset, :nickname, sanitize_name(username))
    else
      changeset
    end
  end
  
  def sanitize_name(name) do
    r1 = Regex.replace(~r/[^\w\d.-@]/, name, "_")
    Regex.replace(~r/\.{2,}/, r1, ".")
  end

  def federated_name do
    @federated_name
  end

  def raw_public_key do
    public_key = Application.get_env(:efossils, :federated_public_key)
    case public_key do
      nil -> {:error, :enoent}
      public_key ->
        File.read(public_key)
    end
  end

  def public_key do
    case raw_public_key() do
      {:ok, content} ->
        case :public_key.pem_decode(content) do
          [] -> {:error, :invalid}
          [pkey] -> :public_key.pem_entry_decode(pkey)
        end
      error ->
        error
    end
  end

  def private_key do
    private_key = Application.get_env(:efossils, :federated_private_key)
    case private_key do
      nil -> {:error, :enoent}
      private_key ->
        with {:ok, content} <- File.read(private_key) do
          case :public_key.pem_decode(content) do
            [] -> {:error, :invalid}
            [pkey] -> {:ok, :public_key.pem_entry_decode(pkey)}
          end
        end
    end
  end

  def sign(msg) do
    {:ok, key} = private_key()
    :public_key.sign(msg, :sha256, key)
  end

  def sign_and_encode(msg) do
     Base.encode64(sign(msg))
  end

  def cast(struct_, vals, keys) do
    Enum.reduce(keys, struct_,
      fn key, struct_ ->
        Map.put(struct_, key, Map.get(vals, Atom.to_string(key)))
      end)
  end
end
