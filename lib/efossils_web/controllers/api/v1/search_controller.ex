defmodule EfossilsWeb.Api.V1.SearchController do
  use EfossilsWeb, :controller
  alias Efossils.Accounts
  
  def user(conn, %{"query" => query}) do
    users = Accounts.search_user(query)
    render(conn, "user.json", users: users)
  end
end
