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
  alias Efossils.Repositories
  alias Efossils.Accounts
  alias Efossils.Repo

  @readonly_capabilities "ghojr2"
  @nobody_capabilities "gjorz2"
  @default_capabilities "cdefgijkmnortuvwxy4"
  @default_capabilities_collaborator "cdefgijkmnortuvwxy4"
  @sources_migration [{"Fossil", "fossil"}, {"GIT", "git"}]
  @sources_pushmirror [{"Fossil", "fossil"}, {"GIT", "git"}]

  def allowed_owners(conn) do
    [{conn.assigns.current_user.name, conn.assigns.current_user.id}]
  end
  def new(conn, _params) do
    users = allowed_owners(conn)
    changeset = Accounts.change_repository(
      %Accounts.Repository{owner_id: conn.assigns[:current_user].id}
    )
    render(conn, "new.html",
      changeset: changeset,
      users: users,
      licenses: build_list_licenses())
  end

  
  def create(conn, %{"repository" => repository_params}) do
    users = allowed_owners(conn)

    repository_params = repository_params
    |> Map.put("owner_id", conn.assigns[:current_user].id)
    |> Accounts.Repository.prepare_attrs

    login_username = conn.assigns[:current_user].nickname
    result = Ecto.Multi.new()
    |> Ecto.Multi.run(:repository, fn repo, %{} ->
      Accounts.create_repository(repository_params)
    end)
    |> Ecto.Multi.run(:ctx, fn repo, %{repository: repository} ->
      Accounts.context_repository(repository)
    end)
    |> Ecto.Multi.run(:commands, fn repo, %{repository: repository, ctx: ctx} ->
      with {:ok, ctx} <- Efossils.Command.new_user(ctx, login_username,
        EfossilsWeb.Utils.public_id(conn.assigns[:current_user]),
        conn.assigns[:current_user].email),
      {:ok, _} <- Efossils.Command.force_setting(ctx, "project-name", repository.name),
      {:ok, _} <- Efossils.Command.force_setting(ctx, "project-description", repository.description),
      {:ok, _} <- Efossils.Command.force_setting(ctx, "short-project-name", repository.nickname),
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
      {:ok, ctx} <- Efossils.Command.capabilities_user(ctx, "nobody", @nobody_capabilities),
        do: {:ok, ctx}
    end)
    |> Ecto.Multi.run(:update_ctx, fn repo, %{commands: ctx, repository: repository} ->
      Accounts.update_repository(repository, Enum.into(ctx, %{}))
    end)
    
    case Repo.transaction(result) do
      {:ok, %{repository: repository}} ->
        if repository_params["project_code"] != "" do
          {:ok, ctx} = Accounts.context_repository(repository)
	        Efossils.Command.force_setting(ctx, "project-code", repository_params["project_code"])
        end
        Accounts.update_repository(repository, %{"project_code" => Accounts.repository_project_code(repository)})
        conn
        |> put_flash(:info, "Repository created successfully.")
        |> redirect(to: "/dashboard")
      {:error, :commands, error, %{ctx: ctx}} ->
        Efossils.Command.delete_repository(ctx)
        changeset = Accounts.Repository.changeset(%Accounts.Repository{})
        |> Ecto.Changeset.add_error(:name, inspect(error))
        render(conn, "new.html",
          changeset: changeset,
          users: users,
          licenses: build_list_licenses())
      {:error, :repository, %Ecto.Changeset{} = changeset, _} ->
        render(conn, "new.html",
          changeset: changeset,
          users: users,
          licenses: build_list_licenses())
      {:error, _, error, _} ->
        changeset = Accounts.Repository.changeset(%Accounts.Repository{})
        |> Ecto.Changeset.add_error(:name, inspect(error))
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
    pushmirrors = Repositories.list_push_mirrors(repository)
    changeset = Accounts.change_repository(repository)
    changeset_pushmirror = Repositories.change_push_mirror(
      %Repositories.PushMirror{repository_id: repository.id}
    )
    
    render(conn, "edit.html", repository: repository,
      changeset: changeset,
      changeset_pushmirror: changeset_pushmirror,
      sources_pushmirror: @sources_pushmirror,
      pushmirrors: pushmirrors,
      collaborations: collaborations)
  end

  def update(conn, %{"id" => id, "repository" => params}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    with_owner_params = Map.put(params, "owner_id", conn.assigns[:current_user].id)
    collaborations = Accounts.list_collaborations(repository)
    pushmirrors = Repositories.list_push_mirrors(repository)
    changeset_pushmirror = Repositories.change_push_mirror(
      %Repositories.PushMirror{repository_id: repository.id}
    )

    case Accounts.update_repository(repository, with_owner_params) do
      {:ok, repository} ->
        conn
        |> put_flash(:info, "Repository updated successfully.")
        |> redirect(to: "/dashboard")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", repository: repository,
          changeset: changeset, changeset_pushmirror: changeset_pushmirror,
          sources_pushmirror: @sources_pushmirror,
          pushmirrors: pushmirrors,
          collaborations: collaborations)
    end
  end

  def delete_repository(conn, %{"repository_id" => id, "repository" => params}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    changeset = Accounts.change_repository(repository)
    collaborations = Accounts.list_collaborations(repository)
    pushmirrors = Repositories.list_push_mirrors(repository)
    changeset_pushmirror = Repositories.change_push_mirror(
      %Repositories.PushMirror{repository_id: repository.id}
    )

    if repository.name == String.trim(params["confirm_name"]) do
      {:ok, _} = Accounts.delete_repository(repository)
      {:ok, ctx} = Accounts.context_repository(repository)
      {:ok, _} = Efossils.Command.delete_repository(ctx)
      conn
      |> put_flash(:info, "Repository delete successfully.")
      |> redirect(to: "/dashboard")
    else
      Plug.Conn.assign(conn, :delete_error, "Please verify")
      |> render("edit.html", repository: repository,
      changeset: changeset,
      changeset_pushmirror: changeset_pushmirror,
      sources_pushmirror: @sources_pushmirror,
      pushmirrors: pushmirrors,
      collaborations: collaborations)
    end
  end

  def pushmirror_create(conn, %{"push_mirror" => pushmirror_params}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], pushmirror_params["repository_id"])
    changeset = Accounts.change_repository(repository)
    changeset_pushmirror = Repositories.change_push_mirror(
      %Repositories.PushMirror{repository_id: repository.id}
    )
    pushmirrors = Repositories.list_push_mirrors(repository)
    collaborations = Accounts.list_collaborations(repository)


    case Repositories.create_push_mirror(pushmirror_params) do
      {:ok, pushmirror} ->
        pushmirrors = Repositories.list_push_mirrors(repository)
        conn
        |> redirect(to: repository_path(conn, :edit, repository))
      {:error, %Ecto.Changeset{} = changeset_pushmirror} ->
        conn
        |> render("edit.html", repository: repository,
        changeset: changeset,
        changeset_pushmirror: changeset_pushmirror,
        pushmirrors: pushmirrors,
        sources_pushmirror: @sources_pushmirror,
        collaborations: collaborations)
    end
  end

  def pushmirror_delete(conn, %{"repository_id" => repository_id, "push_mirror_id" => id}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], repository_id)
    pushmirror = Repositories.get_push_mirror!(id)
    Repositories.delete_push_mirror(pushmirror)
    conn
    |> redirect(to: repository_path(conn, :edit, repository))
  end

  def collaboration_create(conn, %{"repository_id" => id, "username" => username}) do
    repository = Accounts.get_repository!(conn.assigns[:current_user], id)
    changeset = Accounts.change_repository(repository)
    changeset_pushmirror = Repositories.change_push_mirror(
      %Repositories.PushMirror{repository_id: repository.id}
    )
    collaborations = Accounts.list_collaborations(repository)
    pushmirrors = Repositories.list_push_mirrors(repository)
    capabilities_collaborator = if repository.is_mirror do
      @readonly_capabilities
    else
      @default_capabilities_collaborator
    end

    case Accounts.get_user_by_name(username) do
      nil ->
        Plug.Conn.assign(conn, :collaboration_error, "User not found")
        |> render("edit.html", repository: repository, changeset: changeset, collaborations: collaborations)
      collaborator ->
        attrs = %{repository_id: repository.id,
                  user_id: collaborator.id,
                  capabilities: capabilities_collaborator,
                  fossil_username: collaborator.email,
                  fossil_password: collaborator.email,
                 }

        login_username = collaborator.nickname
        case Accounts.create_collaboration(attrs) do
          {:ok, _}  ->

            {:ok, ctx} = Accounts.context_repository(repository)
            {:ok, _} = Efossils.Command.new_user(ctx, login_username,
              EfossilsWeb.Utils.public_id(collaborator), collaborator.email)
            {:ok, _} = Efossils.Command.capabilities_user(ctx, login_username, capabilities_collaborator)
            {:ok, _} = Efossils.Command.Collaborative.append_assigned_to(ctx, login_username)
            
            collaborations = Accounts.list_collaborations(repository)
            conn
            |> render("edit.html", repository: repository,
            changeset: changeset, changeset_pushmirror: changeset_pushmirror,
            sources_pushmirror: @sources_pushmirror,
            pushmirrors: pushmirrors,
            collaborations: collaborations)
          {:error, _} ->
            Plug.Conn.assign(conn, :collaboration_error, "User exists")
            |> render("edit.html", repository: repository,
            changeset: changeset, changeset_pushmirror: changeset_pushmirror,
            sources_pushmirror: @sources_pushmirror,
            pushmirrors: pushmirrors,
            collaborations: collaborations)
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
    Efossils.Command.Collaborative.remove_assigned_to(ctx, collaboration.user.nickname)

    conn
    |> redirect(to: repository_path(conn, :edit, repository))
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
    users = allowed_owners(conn)
    repository_params = repository_params
    |> Map.put("owner_id", conn.assigns[:current_user].id)
    |> Accounts.Repository.prepare_attrs
    login_username = conn.assigns[:current_user].nickname

    source = repository_params["source"]
    source_url = repository_params["source_url"]
    source_username = Map.get(repository_params, "source_username", nil)
    source_password = Map.get(repository_params, "source_password", nil)

    default_perms = "dei2"
    default_capabilities = @default_capabilities
    nobody_capabilities = @nobody_capabilities
    if repository_params["is_mirror"] == "true" do
      userinfo = [URI.encode_www_form(source_username), URI.encode_www_form(source_password)]
      |> Enum.reject(&(&1 == "" or &1 == ''))
      |> Enum.join(":")

      url = URI.parse(repository_params["source_url"])
      |> Map.put(:userinfo, (if userinfo != "", do: userinfo, else: nil))
      repository_params = repository_params
      |> Map.put("clone_url", URI.to_string(url))

      default_perms = @readonly_capabilities
      default_capabilities = @readonly_capabilities
      nobody_capabilities = @readonly_capabilities
    end

    changeset =  %Accounts.Repository{}
    |> Accounts.Repository.changeset(repository_params)

    result = Ecto.Multi.new()
    |> Ecto.Multi.run(:migrate_path, fn repo, _ ->
      Efossils.Command.migrate_repository(repository_params["source"],
        repository_params["source_url"], [username: source_username,
                                          password: source_password])
    end)
    |> Ecto.Multi.run(:repository, fn repo, _ ->
      Efossils.Repo.insert(changeset)
    end)
    |> Ecto.Multi.run(:ctx, fn repo, %{repository: repository, migrate_path: migrate_path} ->
                  with {:ok, ctx} <- Accounts.context_repository_from_migrate(migrate_path, repository),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "project-name", repository.name),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "project-description", repository.description),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "short-project-name", repository.nickname),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-doc", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-tkt", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-wiki", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-technote", "1"),
                  {:ok, _} <- Efossils.Command.force_setting(ctx, "search-ci", "0"),
                  {:ok, _} <- Efossils.Command.setting(ctx, "default-perms", default_perms),
                  {:ok, _} <- Efossils.Command.new_user(ctx, login_username,
                    EfossilsWeb.Utils.public_id(conn.assigns[:current_user]),
                    conn.assigns[:current_user].email),
                  {:ok, _} <- Efossils.Command.capabilities_user(ctx, login_username, default_capabilities),
                  {:ok, _} <- Efossils.Command.config_import(ctx, "fossil.skin"),
                  {:ok, _} <- Efossils.Command.config_import(ctx, "fossil.ticket.skin"),
                  {:ok, _} <- Efossils.Command.Collaborative.append_assigned_to(ctx, login_username),
                  {:ok, ctx} <- Efossils.Command.capabilities_user(ctx, "nobody", nobody_capabilities),
      do: {:ok, ctx}
    end)
    |> Ecto.Multi.run(:update_ctx, fn rep, %{repository: repository, ctx: ctx} ->
      Accounts.update_repository(repository, Enum.into(ctx, %{}))
    end)

    case Repo.transaction(result) do
      {:ok, %{repository: repository}} ->
        conn
        |> put_flash(:info, "Repository created successfully.")
        |> redirect(to: "/dashboard")
      {:error, _, :authentication, _} ->
        changeset = changeset
        |> Ecto.Changeset.add_error(:source_url, "failed authentication")

        render(conn, "migrate.html",
          changeset: changeset,
          users: users,
          sources: @sources_migration,
          licenses: build_list_licenses())
      {:error, _, :required_authentication, _} ->
        changeset = changeset
        |> Ecto.Changeset.add_error(:source_url, "required authentication")

        render(conn, "migrate.html",
          changeset: changeset,
          users: users,
          sources: @sources_migration,
          licenses: build_list_licenses())
      {:error, :repository, %Ecto.Changeset{} = changeset, _} ->
        render(conn, "migrate.html",
          changeset: changeset,
          users: users,
          sources: @sources_migration,
          licenses: build_list_licenses())
      {:error, :update_ctx, %Ecto.Changeset{} = changeset, %{ctx: ctx}} ->
        Efossils.Command.delete_repository(ctx)
        render(conn, "migrate.html",
          changeset: changeset,
          users: users,
          sources: @sources_migration,
          licenses: build_list_licenses())
      # TODO : mientras se afina
      {:error, _, error, _} ->
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
