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

defmodule Efossils.Accounts do
  @moduledoc """
  The Accounts context.
  """
  alias Ecto.Multi
  import Ecto.Query, warn: false
  alias Efossils.Repo

  alias Efossils.Accounts.Repository
  alias Efossils.Coherence.User

  @doc """
  Inicializa gestión del repository por medio de `Efossils.Command`.
  """
  def context_repository(repo, opts \\ []) do
    Efossils.Command.init_repository(Integer.to_string(repo.id),
      Integer.to_string(repo.owner_id), opts)
  end

  def context_repository_from_migrate(migrate_path, repo, opts \\ []) do
    Efossils.Command.init_from_db(migrate_path, Integer.to_string(repo.id),
      Integer.to_string(repo.owner_id), opts)
  end
  
  @doc """
  Returns the list of repositories.

  ## Examples

      iex> list_repositories()
      [%Repository{}, ...]

  """
  def list_repositories do
    Repo.all(Repository)
    |> Repo.preload([:base_repository, :owner])
  end

  def query_repositories_by_owner(owner) do
    from r in Repository,
      left_join: colab in Efossils.Accounts.Collaboration,
      on: colab.repository_id == r.id,
      where: r.owner_id == ^owner.id or colab.user_id == ^owner.id,
      order_by: [desc: :inserted_at],
      preload: [:base_repository, :owner],
      group_by: r.id
  end
  
  def list_repositories_by_owner(owner) do
    Repo.all(from r in Repository,
      left_join: colab in Efossils.Accounts.Collaboration,
      on: colab.repository_id == r.id,
      where: r.owner_id == ^owner.id or colab.user_id == ^owner.id,
      order_by: [desc: :inserted_at]
    )
    |> Repo.preload([:base_repository, :owner])
  end
  
  @doc """
  Gets a single repository.

  Raises `Ecto.NoResultsError` if the Repository does not exist.

  ## Examples

      iex> get_repository!(123)
      %Repository{}

      iex> get_repository!(456)
      ** (Ecto.NoResultsError)

  """
  def get_repository!(id), do: Repo.get!(Repository, id) |> Repo.preload([:base_repository, :owner])
  def get_repository_by_name!(name) do
    Repo.get_by!(Repository, lower_name: name)
    |> Repo.preload([:base_repository, :owner])
  end
  def get_repository!(owner, id) do
    Repo.get_by!(Repository, owner_id: owner.id, id: id)
    |> Repo.preload([:base_repository, :owner])
  end
  @doc """
  Creates a repository.

  ## Examples

      iex> create_repository(%{field: value})
      {:ok, %Repository{}}

      iex> create_repository(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
      
  """
  def create_repository(attrs \\ %{}) do
    changeset = %Repository{}
    |> Repository.changeset(attrs)
    |> Repository.validate_max_repositories
    
    case Repo.insert(changeset) do
      {:ok, repository} ->
        from(u in User, where: u.id == ^repository.owner_id)
        |> Repo.update_all(inc: [num_repos: 1])
        {:ok, repository}
      error -> error
    end
  end

  @doc """
  Updates a repository.

  ## Examples

      iex> update_repository(repository, %{field: new_value})
      {:ok, %Repository{}}

      iex> update_repository(repository, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_repository(%Repository{} = repository, attrs) do
    repository
    |> Repository.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Repository.

  ## Examples

      iex> delete_repository(repository)
      {:ok, %Repository{}}

      iex> delete_repository(repository)
      {:error, %Ecto.Changeset{}}

  """
  def delete_repository(%Repository{} = repository) do
    Repo.transaction fn ->
      Repo.delete_all(from(c in Efossils.Accounts.Collaboration,
            where: c.repository_id == ^repository.id))
      Repo.delete_all(from(c in Efossils.Accounts.Star,
            where: c.repository_id == ^repository.id))
      from(u in User, where: u.id == ^repository.owner_id)
      |> Repo.update_all(inc: [num_repos: -1])
      Repo.delete!(repository)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking repository changes.

  ## Examples

      iex> change_repository(repository)
      %Ecto.Changeset{source: %Repository{}}

  """
  def change_repository(%Repository{} = repository) do
    Repository.changeset(repository, %{})
  end

  alias Efossils.Accounts.Collaboration

  @doc """
  Returns the list of collaborations.

  ## Examples

      iex> list_collaborations()
      [%Collaboration{}, ...]

  """
  def list_collaborations do
    Repo.all(Collaboration)
  end

  def count_collaborations(repo_id) when is_integer(repo_id) do
    Repo.aggregate(from(c in Collaboration, where: c.repository_id == ^repo_id), :count, :id)
  end
  
  def count_collaborations(%Repository{} = repository) do
    Repo.aggregate(from(c in Collaboration, where: c.repository_id == ^repository.id), :count, :id)
  end
  
  def list_collaborations(%Repository{} = repository) do
    Repo.all(from c in Collaboration, where: c.repository_id == ^repository.id)
    |> Repo.preload([:user])
  end
  def list_collaborations(%Efossils.Coherence.User{} = user) do
    Repo.all(from c in Collaboration, where: c.user_id == ^user.id)
    |> Repo.preload([:user])
  end

  @doc """
  Gets a single collaboration.

  Raises `Ecto.NoResultsError` if the Collaboration does not exist.

  ## Examples

      iex> get_collaboration!(123)
      %Collaboration{}

      iex> get_collaboration!(456)
      ** (Ecto.NoResultsError)

  """
  def get_collaboration!(id), do: Repo.get!(Collaboration, id)
  def get_collaboration!(repo, id) do
    Repo.get_by!(Collaboration, repository_id: repo.id, user_id: id)
    |> Repo.preload([:user])
  end
  @doc """
  Creates a collaboration.

  ## Examples

      iex> create_collaboration(%{field: value})
      {:ok, %Collaboration{}}

      iex> create_collaboration(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_collaboration(attrs \\ %{}) do
    %Collaboration{}
    |> Collaboration.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a collaboration.

  ## Examples

      iex> update_collaboration(collaboration, %{field: new_value})
      {:ok, %Collaboration{}}

      iex> update_collaboration(collaboration, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_collaboration(%Collaboration{} = collaboration, attrs) do
    collaboration
    |> Collaboration.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Collaboration.

  ## Examples

      iex> delete_collaboration(collaboration)
      {:ok, %Collaboration{}}

      iex> delete_collaboration(collaboration)
      {:error, %Ecto.Changeset{}}

  """
  def delete_collaboration(%Collaboration{} = collaboration) do
    Repo.delete(collaboration)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking collaboration changes.

  ## Examples

      iex> change_collaboration(collaboration)
      %Ecto.Changeset{source: %Collaboration{}}

  """
  def change_collaboration(%Collaboration{} = collaboration) do
    Collaboration.changeset(collaboration, %{})
  end

  alias Efossils.Accounts.Star

  @doc """
  Returns the list of stars.

  ## Examples

      iex> list_stars()
      [%Star{}, ...]

  """
  def list_stars do
    Repo.all(Star)
  end

  @doc """
  Gets a single star.

  Raises `Ecto.NoResultsError` if the Star does not exist.

  ## Examples

      iex> get_star!(123)
      %Star{}

      iex> get_star!(456)
      ** (Ecto.NoResultsError)

  """
  def get_star!(id), do: Repo.get!(Star, id)

  @doc """
  Creates a star.

  ## Examples

      iex> create_star(%{field: value})
      {:ok, %Star{}}

      iex> create_star(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_star(attrs \\ %{}) do
    %Star{}
    |> Star.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a star.

  ## Examples

      iex> update_star(star, %{field: new_value})
      {:ok, %Star{}}

      iex> update_star(star, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_star(%Star{} = star, attrs) do
    star
    |> Star.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Star.

  ## Examples

      iex> delete_star(star)
      {:ok, %Star{}}

      iex> delete_star(star)
      {:error, %Ecto.Changeset{}}

  """
  def delete_star(%Star{} = star) do
    Repo.delete(star)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking star changes.

  ## Examples

      iex> change_star(star)
      %Ecto.Changeset{source: %Star{}}

  """
  def change_star(%Star{} = star) do
    Star.changeset(star, %{})
  end


  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def change_user_profile(%User{} = user) do
    User.changeset_profile(user, %{})
  end
  
  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.changeset_profile(attrs)
    |> Repo.update()
  end

  def list_users do
    Repo.all(User)
  end

  def get_user_by_name!(name) do
    Repo.get_by!(User, name: name)
  end
  def get_user_by_name(name) do
    Repo.get_by(User, name: name)
  end

  def is_user_collaborator_for_repository(user, repository) do
    Repo.aggregate(from( c in Collaboration,
          where: c.repository_id == ^repository.id and c.user_id == ^user.id),
      :count, :id) > 0
  end

  def search_user(query) do
    like_query = "%#{query}%"
    Repo.all(from u in User,
      where: fragment("? ilike ?", u.name, ^like_query))
  end
end
