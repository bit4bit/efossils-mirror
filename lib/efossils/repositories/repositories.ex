defmodule Efossils.Repositories do
  @moduledoc """
  The Repositories context.
  """

  import Ecto.Query, warn: false
  alias Efossils.Repo

  alias Efossils.Accounts
  alias Efossils.Repositories.PushMirror

  @doc """
  Returns the list of push_mirrors.

  ## Examples

      iex> list_push_mirrors()
      [%PushMirror{}, ...]

  """
  def list_push_mirrors(repository = %Accounts.Repository{}) do
    Repo.all(from t in PushMirror, where: t.repository_id == ^repository.id)
  end

  @doc """
  Gets a single push_mirror.

  Raises `Ecto.NoResultsError` if the Push mirror does not exist.

  ## Examples

      iex> get_push_mirror!(123)
      %PushMirror{}

      iex> get_push_mirror!(456)
      ** (Ecto.NoResultsError)

  """
  def get_push_mirror!(id), do: Repo.get!(PushMirror, id)

  @doc """
  Creates a push_mirror.

  ## Examples

      iex> create_push_mirror(%{field: value})
      {:ok, %PushMirror{}}

      iex> create_push_mirror(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_push_mirror(attrs \\ %{}) do
    %PushMirror{}
    |> PushMirror.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a push_mirror.

  ## Examples

      iex> update_push_mirror(push_mirror, %{field: new_value})
      {:ok, %PushMirror{}}

      iex> update_push_mirror(push_mirror, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_push_mirror(%PushMirror{} = push_mirror, attrs) do
    push_mirror
    |> PushMirror.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PushMirror.

  ## Examples

      iex> delete_push_mirror(push_mirror)
      {:ok, %PushMirror{}}

      iex> delete_push_mirror(push_mirror)
      {:error, %Ecto.Changeset{}}

  """
  def delete_push_mirror(%PushMirror{} = push_mirror) do
    Repo.delete(push_mirror)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking push_mirror changes.

  ## Examples

      iex> change_push_mirror(push_mirror)
      %Ecto.Changeset{source: %PushMirror{}}

  """
  def change_push_mirror(%PushMirror{} = push_mirror) do
    PushMirror.changeset(push_mirror, %{})
  end
end
