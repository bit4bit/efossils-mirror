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

defmodule EfossilsWeb.LayoutView do
  use EfossilsWeb, :view
end

# Esto es requerido por 'pow' ya que sin esto
# no permite usar los layouts
defmodule EfossilsWeb.Phoenix.LayoutView do
  use Phoenix.View, root: "lib/efossils_web/templates",
    path: "layout",
    namespace: EfossilsWeb
  # Import convenience functions from controllers
  import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

  # Use all HTML functionality (forms, tags, etc)
  use Phoenix.HTML

  import EfossilsWeb.Router.Helpers
  import EfossilsWeb.ErrorHelpers
  import EfossilsWeb.Gettext
end
