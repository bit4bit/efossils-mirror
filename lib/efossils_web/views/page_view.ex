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

defmodule EfossilsWeb.PageView do
  use EfossilsWeb, :view
  import Scrivener.HTML
  import EfossilsWeb.EfossilsHelper
  import Ecto.Query, warn: false
  alias Efossils.Accounts.Repository
  alias Efossils.User
  alias Efossils.Repo

  def statistic_num_public_repositories do
    (from r in Repository,
      where: r.is_private == false)
    |> Repo.aggregate(:count, :id)
  end

  def statistic_num_private_repositories do
    (from r in Repository,
      where: r.is_private == true)
    |> Repo.aggregate(:count, :id)
  end

  def statistic_num_members do
    Repo.aggregate(User, :count, :id)
  end
end
