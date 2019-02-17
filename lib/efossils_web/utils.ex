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

defmodule EfossilsWeb.Utils do
  @moduledoc false
  alias Efossils.User
  alias Efossils.Accounts.Collaboration

  defdelegate fossil_path(rest, user, repo), to: Efossils.Utils

  def public_id(%User{nickname: nickname}) do
    "#{base_url()}/users/#{nickname}"
  end
  
  def public_id(%Collaboration{user: user}) do
    "#{base_url()}/users/#{user.nickname}"
  end

  def public_id(:instance) do
    "#{base_url()}/instance"
  end

  def inbox_url(:instance) do
    "#{base_url()}/inbox"
  end


  def base_url do
    EfossilsWeb.Endpoint.url()
  end
end
