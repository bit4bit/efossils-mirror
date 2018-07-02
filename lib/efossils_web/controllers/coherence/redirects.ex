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

defmodule Coherence.Redirects do
  @moduledoc """
  Define controller action redirection functions.

  This module contains default redirect functions for each of the controller
  actions that perform redirects. By using this Module you get the following
  functions:

  * session_create/2
  * session_delete/2
  * password_create/2
  * password_update/2,
  * unlock_create_not_locked/2
  * unlock_create_invalid/2
  * unlock_create/2
  * unlock_edit_not_locked/2
  * unlock_edit/2
  * unlock_edit_invalid/2
  * registration_create/2
  * invitation_create/2
  * confirmation_create/2
  * confirmation_edit_invalid/2
  * confirmation_edit_expired/2
  * confirmation_edit/2
  * confirmation_edit_error/2

  You can override any of the functions to customize the redirect path. Each
  function is passed the `conn` and `params` arguments from the controller.

  ## Examples

      import EfossilsWeb.Router.Helpers

      # override the log out action back to the log in page
      def session_delete(conn, _), do: redirect(conn, to: session_path(conn, :new))

      # redirect the user to the login page after registering
      def registration_create(conn, _), do: redirect(conn, to: session_path(conn, :new))

      # disable the user_return_to feature on login
      def session_create(conn, _), do: redirect(conn, to: landing_path(conn, :index))

  """
  use Redirects
  # Uncomment the import below if adding overrides
  import EfossilsWeb.Router.Helpers

  # Add function overrides below

  # Example usage
  # Uncomment the following line to return the user to the login form after logging out
  # def session_delete(conn, _), do: redirect(conn, to: session_path(conn, :new))

  def session_create(conn, _), do: redirect(conn, to: page_path(conn, :dashboard))
  def session_delete(conn, _), do: redirect(conn, to: "/")
end
