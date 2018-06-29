defmodule EfossilsWeb.PageController do
  use EfossilsWeb, :controller
  alias Efossils.Accounts
  
  def index(conn, _params) do
    render conn, "index.html"
  end

  def dashboard(conn, _params) do
    repositories = Accounts.list_repositories_by_owner(conn.assigns[:current_user])
    render conn, "dashboard.html", repositories: repositories
  end
end
