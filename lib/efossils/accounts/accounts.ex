defmodule Efossils.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Efossils.Repo

  alias Efossils.Accounts.Repository

  @doc """
  Returns the list of repositories.

  ## Examples

      iex> list_repositories()
      [%Repository{}, ...]

  """
  def list_repositories do
    Repo.all(Repository)
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
  def get_repository!(id), do: Repo.get!(Repository, id)

  @doc """
  Creates a repository.

  ## Examples

      iex> create_repository(%{field: value})
      {:ok, %Repository{}}

      iex> create_repository(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_repository(attrs \\ %{}) do
    %Repository{}
    |> Repository.changeset(attrs)
    |> Repo.insert()
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
    Repo.delete(repository)
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
end
