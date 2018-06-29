defmodule EfossilsWeb.Router do
  use EfossilsWeb, :router
  use Coherence.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    #plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_layout, {EfossilsWeb.LayoutView, :page}
    plug Coherence.Authentication.Session
  end

  pipeline :protected do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    #plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_layout, {EfossilsWeb.LayoutView, :app}
    plug Coherence.Authentication.Session, protected: true  # Add this
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
    resources "/repositories", RepositoryController

  end
  
  # Other scopes may use custom stacks.
  # scope "/api", EfossilsWeb do
  #   pipe_through :api
  # end
end
