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

defmodule EfossilsWeb.ProfileController do
  use EfossilsWeb, :controller
  alias Efossils.Accounts
  
  def index(conn, _params) do
    changeset = Accounts.change_user_profile(conn.assigns[:current_user])
    render conn, "index.html", changeset: changeset
  end

  def update(conn, %{"user" => user_params}) do
    case Accounts.update_user_profile(conn.assigns[:current_user], user_params) do
      {:ok, user} ->
        Pow.Phoenix.SessionController.process_delete(conn, %{})
        |> Pow.Phoenix.SessionController.respond_delete
      {:error, %Ecto.Changeset{} = changeset} ->
        render conn, "index.html", changeset: changeset
    end
  end
end
