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

defmodule EfossilsWeb.ExploreRepositoriesController do
  use EfossilsWeb, :controller
  import Ecto.Query, warn: false
  alias Efossils.Accounts

  def index_by_username(conn, params) do
    index(conn, params)
  end
  
  def index(conn, params) do
    order_by = case params["order_by"] do
                 "license" ->
                   [asc: :license]
                 "updated-at" ->
                   [desc: :updated_at]
                 _ ->
                   [desc: :inserted_at]
               end

    filter = case params["license"] do
               empty when is_nil(empty) or empty == "" -> []
               license -> [license: license]
             end

    filter_by_username = case params["username"] do
                           empty when is_nil(empty) or empty == "" -> []
                           username ->
                             case Accounts.get_user_by_name(username) do
                               nil -> [owner_id: 0]
                               user -> [owner_id: user.id]
                             end
                         end
    
    repositories = search(Efossils.Accounts.Repository, params["search"])
    |> preload([:base_repository, :owner])
    |> order_by(^order_by)
    |> where(^filter)
    |> where(^filter_by_username)
    |> Efossils.Repo.paginate(params)
    render conn, "index.html", repositories: repositories,
      orderBy: params["order_by"],
      license: params["license"],
      licenses: build_list_licenses()
  end

  defp search(query, ""), do: search(query, nil)
  defp search(query, nil), do: from(u in query, where: u.is_private == false)
  defp search(query, search_term) when is_binary(search_term) do
    from(u in query,                                                
      where: fragment("to_tsvector('english', ? || ?) @@ to_tsquery('english', ?)", u.name, u.description, ^search_term)
    )
  end
  
  defp build_list_licenses() do
    Enum.map(Accounts.Repository.licenses, fn {code, license} ->
      {license.name, code}
    end)
  end

end
