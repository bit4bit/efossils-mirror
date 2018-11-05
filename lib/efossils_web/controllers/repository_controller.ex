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

defmodule EfossilsWeb.RepositoryController do
  use EfossilsWeb, :controller
  alias Efossils.Accounts
  alias Efossils.Repo

  @default_capabilities "cdefgijkmnortuvwx4"
  @default_capabilities_collaborator "cdefgijkmnortuvwx4"
  @sources_migration [{"GIT", "git"}, {"Fossil", "fossil"}]
  
  def new(conn, _params) do
    users = Enum.map(Accounts.list_users, &({&1.name, &1.id}))
    changeset = Accounts.change_repository(
      %Accounts.Repository{owner_id: conn.assigns[:current_user].id}
    )
      
    render(conn, "new.html",
      changeset: changeset,
      users: users,
      licenses: build_list_licenses())
  end

  
  def create(conn, %{"repository" => repository_params}) do
    
    repository_params = repository_params
    |> Map.put("owner_id", conn.assigns[:current_user].id)
    |> Accounts.Repository.prepare_attrs

    login_username = conn.assigns[:current_user].lower_name
    result = with {:ok, repository} <- Accounts.create_repository(repository_params),
                  {:ok, ctx} <- Accounts.context_repository(repository,
                    default_username: login_username),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "project-name", repository.name),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "project-description", repository.description),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "short-project-name", repository.lower_name),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-doc", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-tkt", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-wiki", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-technote", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-ci", "0"),
                  {:ok, _} <- Efossils.Command.setting(ctx, "default-perms", "dei2"),
                  {:ok, _} <- Efossils.Command.password_user(ctx,
                    login_username, conn.assigns[:current_user].email),
                  {:ok, _} <- Efossils.Command.capabilities_user(ctx, login_username, @default_capabilities),
                  {:ok, _} <- Efossils.Command.config_import(ctx, "fossil.skin"),
                  {:ok, _} <- Efossils.Command.config_import(ctx, "fossil.ticket.skin"),
                  {:ok, _} <- Efossils.Command.Collaborative.append_assigned_to(ctx, login_username),
                  {:ok, _} <- Accounts.update_repository(repository, Enum.into(ctx, %{})),
      do: {:ok, repository}
    
    case result do
      {:ok, repository} ->
        conn
        |> put_flash(:info, "Repository created successfully.")
        |> redirect(to: "/dashboard")
      {:error, %Ecto.Changeset{} = changeset} ->
        users = Enum.map(Accounts.list_users, &({&1.name, &1.id}))

        render(conn, "new.html",
          changeset: changeset,
          users: users,
          licenses: build_list_licenses())
    end
  end

  def show(conn, %{"id" => id}) do
    repository = Accounts.get_repository!(id)
    render(conn, "show.html", repository: repository)
  end

  def edit(conn, %{"id" => id}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    collaborations = Accounts.list_collaborations(repository)
    changeset = Accounts.change_repository(repository)
    render(conn, "edit.html", repository: repository, changeset: changeset, collaborations: collaborations)
  end

  def update(conn, %{"id" => id, "repository" => params}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    with_owner_params = Map.put(params, "owner_id", conn.assigns[:current_user].id)
    collaborations = Accounts.list_collaborations(repository)
    case Accounts.update_repository(repository, with_owner_params) do
      {:ok, repository} ->
        conn
        |> put_flash(:info, "Repository updated successfully.")
        |> redirect(to: "/dashboard")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", repository: repository, changeset: changeset, collaborations: collaborations)
    end
  end

  def delete_repository(conn, %{"repository_id" => id, "repository" => params}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    changeset = Accounts.change_repository(repository)
    collaborations = Accounts.list_collaborations(repository)
    if repository.name == String.trim(params["confirm_name"]) do
      {:ok, _} = Accounts.delete_repository(repository)
      {:ok, ctx} = Accounts.context_repository(repository)
      {:ok, _} = Efossils.Command.delete_repository(ctx)
      conn
      |> put_flash(:info, "Repository delete successfully.")
      |> redirect(to: "/dashboard")
    else
      Plug.Conn.assign(conn, :delete_error, "Please verify")
      |> render("edit.html", repository: repository, changeset: changeset, collaborations: collaborations)
    end
  end

  def collaboration_create(conn, %{"repository_id" => id, "username" => username}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    changeset = Accounts.change_repository(repository)
    collaborations = Accounts.list_collaborations(repository)
    case Accounts.get_user_by_name(username) do
      nil ->
        Plug.Conn.assign(conn, :collaboration_error, "User not found")
        |> render("edit.html", repository: repository, changeset: changeset, collaborations: collaborations)
      collaborator ->
        attrs = %{repository_id: repository.id,
                  user_id: collaborator.id,
                  capabilities: @default_capabilities_collaborator,
                  fossil_username: collaborator.email,
                  fossil_password: collaborator.email,
                 }
        case Accounts.create_collaboration(attrs) do
          {:ok, _}  ->
            {:ok, ctx} = Accounts.context_repository(repository)
            {:ok, _} = Efossils.Command.new_user(ctx, collaborator.lower_name, collaborator.id, collaborator.email)
            {:ok, _} = Efossils.Command.capabilities_user(ctx, collaborator.lower_name, @default_capabilities_collaborator)
            {:ok, _} = Efossils.Command.Collaborative.append_assigned_to(ctx, collaborator.lower_name)
            
            collaborations = Accounts.list_collaborations(repository)
            conn
            |> render("edit.html", repository: repository, changeset: changeset, collaborations: collaborations)
          {:error, _} ->
            Plug.Conn.assign(conn, :collaboration_error, "User exists")
            |> render("edit.html", repository: repository, changeset: changeset, collaborations: collaborations)
        end
    end
    
  end

  def collaboration_delete(conn, %{"repository_id" => id, "user_id" => collaborator_id}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    collaboration = Accounts.get_collaboration!(repository, collaborator_id)
    changeset = Accounts.change_repository(repository)

    {:ok, _} = Accounts.delete_collaboration(collaboration)
    collaborations = Accounts.list_collaborations(repository)
    
    {:ok, ctx} = Accounts.context_repository(repository)
    Efossils.Command.Collaborative.remove_assigned_to(ctx, collaboration.user.lower_name)
    
    render(conn, "edit.html", repository: repository, changeset: changeset, collaborations: collaborations)
  end

  def migrate_new(conn, _params) do
    users = Enum.map(Accounts.list_users, &({&1.name, &1.id}))
    changeset = Accounts.change_repository(
      %Accounts.Repository{owner_id: conn.assigns[:current_user].id}
    )
    render(conn, "migrate.html", users: users,
      changeset: changeset,
      sources: @sources_migration,
      licenses: build_list_licenses())
  end

  def migrate_create(conn, %{"repository" => repository_params}) do
    repository_params = repository_params
    |> Map.put("owner_id", conn.assigns[:current_user].id)
    |> Accounts.Repository.prepare_attrs
    login_username = conn.assigns[:current_user].lower_name

    source = repository_params["source"]
    source_url = repository_params["source_url"]
    source_username = Map.get(repository_params, "source_username", nil)
    source_password = Map.get(repository_params, "source_password", nil)
    changeset =  %Accounts.Repository{}
    |> Accounts.Repository.changeset(repository_params)
    
    result = with {:ok, migrate_path} <- Efossils.Command.migrate_repository(repository_params["source"],
                       repository_params["source_url"], [username: source_username,
                                                         password: source_password]),
                  {:ok, repository} <- Efossils.Repo.insert(changeset),
                  {:ok, ctx} <- Accounts.context_repository_from_migrate(migrate_path, repository,
                    default_username: login_username),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "project-name", repository.name),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "project-description", repository.description),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "short-project-name", repository.lower_name),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-doc", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-tkt", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-wiki", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-technote", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-ci", "0"),
                  {:ok, _} <- Efossils.Command.setting(ctx, "default-perms", "dei"),
                  {:ok, _} <- Efossils.Command.new_user(ctx,
                    login_username, conn.assigns[:current_user].id, conn.assigns[:current_user].email),
                  {:ok, _} <- Efossils.Command.capabilities_user(ctx, login_username, @default_capabilities),
                  {:ok, _} <- Efossils.Command.config_import(ctx, "fossil.skin"),
                  {:ok, _} <- Accounts.update_repository(repository, Enum.into(ctx, %{})),
      do: {:ok, repository}
    
    case result do
      {:ok, repository} ->
        conn
        |> put_flash(:info, "Repository created successfully.")
        |> redirect(to: "/dashboard")
      {:error, :authentication} ->
        users = Enum.map(Accounts.list_users, &({&1.name, &1.id}))
        
        changeset = changeset
        |> Ecto.Changeset.add_error(:source_url, "failed authentication")

        render(conn, "migrate.html",
          changeset: changeset,
          users: users,
          sources: @sources_migration,
          licenses: build_list_licenses())
      {:error, :required_authentication} ->
        users = Enum.map(Accounts.list_users, &({&1.name, &1.id}))
        
        changeset = changeset
        |> Ecto.Changeset.add_error(:source_url, "required authentication")

        render(conn, "migrate.html",
          changeset: changeset,
          users: users,
          sources: @sources_migration,
          licenses: build_list_licenses())
      {:error, %Ecto.Changeset{} = changeset} ->
        users = Enum.map(Accounts.list_users, &({&1.name, &1.id}))

        render(conn, "migrate.html",
          changeset: changeset,
          users: users,
          sources: @sources_migration,
          licenses: build_list_licenses())
      # TODO : mientras se afina
      {:error, error} ->
        users = Enum.map(Accounts.list_users, &({&1.name, &1.id}))
        
        changeset = changeset
        |> Ecto.Changeset.add_error(:source_url, inspect error)

        render(conn, "migrate.html",
          changeset: changeset,
          users: users,
          sources: @sources_migration,
          licenses: build_list_licenses())
    end
  end

  defp build_list_licenses() do
    Enum.map(Accounts.Repository.licenses, fn {code, license} ->
      {license.name, code}
    end)
  end
  
end
