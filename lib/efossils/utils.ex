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
end
