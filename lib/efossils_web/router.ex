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
