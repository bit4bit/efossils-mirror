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

defmodule EfossilsWeb.Router do
  use EfossilsWeb, :router
  use Coherence.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session
    plug :put_layout_from_session
  end
  
  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Coherence.Authentication.Session, protected: true  # Add this
    plug :put_layout_from_session
  end

  pipeline :put_session do
    plug :fetch_session
  end
  
  scope "/" do
    pipe_through :browser
    coherence_routes()
  end
  
  scope "/" do
    pipe_through :protected
    coherence_routes :protected
  end

  scope "/fossil", EfossilsWeb do
    pipe_through :put_session
    forward "/", Proxy.Plug
  end
  
  scope "/", EfossilsWeb do
    pipe_through :browser # Use the default browser stack
    
    get "/", PageController, :index
    get "/explore/repositories", ExploreRepositoriesController, :index
  end

  scope "/", EfossilsWeb do
    pipe_through :protected

    get "/dashboard", PageController, :dashboard
    get "/", PageController, :dashboard
    resources "/repositories", RepositoryController do
      put "/delete", RepositoryController, :delete_repository, as: :settings
      post "/collaboration/add", RepositoryController, :collaboration_create, as: :collaboration
      delete "/collaboration/:user_id/delete", RepositoryController, :collaboration_delete, as: :collaboration
    end

  end

  scope "/api/v1", EfossilsWeb do
    pipe_through :protected
    get "/search/user", Api.V1.SearchController, :user
  end
  
  defp put_layout_from_session(conn, _) do
    if conn.assigns[:current_user] do
      Phoenix.Controller.put_layout(conn, {EfossilsWeb.LayoutView, :app})
    else
      Phoenix.Controller.put_layout(conn, {EfossilsWeb.LayoutView, :page})
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", EfossilsWeb do
  #   pipe_through :api
  # end
end
