defmodule EfossilsWeb.RepositoryController do
  use EfossilsWeb, :controller
  alias Efossils.Accounts
  alias Efossils.Repo

  def new(conn, _params) do
    licenses = Accounts.Repository.licenses
    users = Enum.map(Accounts.list_users, &({&1.name, &1.id}))
    changeset = Accounts.change_repository(
      %Accounts.Repository{owner_id: conn.assigns[:current_user].id}
    )
      
    render(conn, "new.html",
      changeset: changeset,
      users: users,
      licenses: licenses)
  end

  def create(conn, %{"repository" => repository_params}) do
    
    repository_params = repository_params
    |> Map.put("owner_id", conn.assigns[:current_user].id)
    |> Accounts.Repository.prepare_attrs

    result = with {:ok, repository} <- Accounts.create_repository(repository_params),
                  {:ok, ctx} <- Accounts.context_repository(repository,
                    default_username: conn.assigns[:current_user].email),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "project-name", repository.name),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "project-description", repository.description),
                  {:ok, _} <- Efossils.Command.setting(ctx, "default-perms", "dei"),
                  {:ok, _} <- Efossils.Command.password_user(ctx,
                    conn.assigns[:current_user].email, conn.assigns[:current_user].email),
                  {:ok, _} <- Efossils.Command.capabilities_user(ctx, conn.assigns[:current_user].email, "dei"),
                  {:ok, _} <- Efossils.Command.config_import(ctx, "fossil.skin"),
                  {:ok, _} <- Accounts.update_repository(repository, Enum.into(ctx, %{})),
      do: {:ok, repository}
    
    case result do
      {:ok, repository} ->
        conn
        |> put_flash(:info, "Repository created successfully.")
        |> redirect(to: "/dashboard")
      {:error, %Ecto.Changeset{} = changeset} ->
        licenses = Accounts.Repository.licenses
        users = Enum.map(Accounts.list_users, &({&1.name, &1.id}))

        render(conn, "new.html",
          changeset: changeset,
          users: users,
          licenses: licenses)
    end
  end

  def show(conn, %{"id" => id}) do
    repository = Accounts.get_repository!(id)
    render(conn, "show.html", repository: repository)
  end

  def edit(conn, %{"id" => id}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    changeset = Accounts.change_repository(repository)
    render(conn, "edit.html", repository: repository, changeset: changeset)
  end

  def update(conn, %{"id" => id, "repository" => params}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    with_owner_params = Map.put(params, "owner_id", conn.assigns[:current_user].id)
    case Accounts.update_repository(repository, with_owner_params) do
      {:ok, repository} ->
        conn
        |> put_flash(:info, "Repository updated successfully.")
        |> redirect(to: "/dashboard")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", repository: repository, changeset: changeset)
    end
  end

  def delete_repository(conn, %{"repository_id" => id, "repository" => params}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    changeset = Accounts.change_repository(repository)
    if repository.name == String.trim(params["confirm_name"]) do
      {:ok, _} = Accounts.delete_repository(repository)
      {:ok, ctx} = Accounts.context_repository(repository)
      {:ok, _} = Efossils.Command.delete_repository(ctx)
      conn
      |> put_flash(:info, "Repository delete successfully.")
      |> redirect(to: "/dashboard")
    else
      Plug.Conn.assign(conn, :delete_error, "Please verify")
      |> render("edit.html", repository: repository, changeset: changeset)
    end
  end
end
