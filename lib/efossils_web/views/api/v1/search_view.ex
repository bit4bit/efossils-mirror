defmodule EfossilsWeb.Api.V1.SearchView do
  use EfossilsWeb, :view

  def render("user.json", %{users: users}) do
    results = Enum.map(users, fn user ->
      %{"title" => user.name}
    end)
    %{"results" => results}
  end
end
