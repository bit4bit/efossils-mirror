defmodule EfossilsWeb.ExploreRepositoriesController do
  use EfossilsWeb, :controller
  import Ecto.Query, warn: false
  alias Efossils.Accounts
  
  def index(conn, params) do
    order_by = case params["order_by"] do
                 _ ->
                   [desc: :inserted_at]
               end
    repositories = search(Efossils.Accounts.Repository, params["search"])
    |> preload([:base_repository, :owner])
    |> order_by(^order_by)
    |> Efossils.Repo.paginate(params)
    render conn, "index.html", repositories: repositories, orderBy: params["order_by"]
  end

  defp search(query, ""), do: search(query, nil)
  defp search(query, nil), do: from(u in query, where: u.is_private == false)
  defp search(query, search_term) when is_binary(search_term) do
    from(u in query,                                                
      where: fragment("to_tsvector('english', ? || ?) @@ to_tsquery('english', ?)", u.name, u.description, ^search_term)
    )
  end

end
