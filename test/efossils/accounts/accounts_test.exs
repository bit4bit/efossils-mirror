defmodule Efossils.AccountsTest do
  use Efossils.DataCase

  alias Efossils.Accounts

  describe "repositories" do
    alias Efossils.Accounts.Repository

    @valid_attrs %{description: "some description", is_private: true, lowerName: "some lowerName", name: "some name", num_forks: 42, num_stars: 42, num_watchers: 42, size: 42, website: "some website"}
    @update_attrs %{description: "some updated description", is_private: false, lowerName: "some updated lowerName", name: "some updated name", num_forks: 43, num_stars: 43, num_watchers: 43, size: 43, website: "some updated website"}
    @invalid_attrs %{description: nil, is_private: nil, lowerName: nil, name: nil, num_forks: nil, num_stars: nil, num_watchers: nil, size: nil, website: nil}

    def repository_fixture(attrs \\ %{}) do
      {:ok, repository} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_repository()

      repository
    end

    test "list_repositories/0 returns all repositories" do
      repository = repository_fixture()
      assert Accounts.list_repositories() == [repository]
    end

    test "get_repository!/1 returns the repository with given id" do
      repository = repository_fixture()
      assert Accounts.get_repository!(repository.id) == repository
    end

    test "create_repository/1 with valid data creates a repository" do
      assert {:ok, %Repository{} = repository} = Accounts.create_repository(@valid_attrs)
      assert repository.description == "some description"
      assert repository.is_private == true
      assert repository.lowerName == "some lowerName"
      assert repository.name == "some name"
      assert repository.num_forks == 42
      assert repository.num_stars == 42
      assert repository.num_watchers == 42
      assert repository.size == 42
      assert repository.website == "some website"
    end

    test "create_repository/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_repository(@invalid_attrs)
    end

    test "update_repository/2 with valid data updates the repository" do
      repository = repository_fixture()
      assert {:ok, repository} = Accounts.update_repository(repository, @update_attrs)
      assert %Repository{} = repository
      assert repository.description == "some updated description"
      assert repository.is_private == false
      assert repository.lowerName == "some updated lowerName"
      assert repository.name == "some updated name"
      assert repository.num_forks == 43
      assert repository.num_stars == 43
      assert repository.num_watchers == 43
      assert repository.size == 43
      assert repository.website == "some updated website"
    end

    test "update_repository/2 with invalid data returns error changeset" do
      repository = repository_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_repository(repository, @invalid_attrs)
      assert repository == Accounts.get_repository!(repository.id)
    end

    test "delete_repository/1 deletes the repository" do
      repository = repository_fixture()
      assert {:ok, %Repository{}} = Accounts.delete_repository(repository)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_repository!(repository.id) end
    end

    test "change_repository/1 returns a repository changeset" do
      repository = repository_fixture()
      assert %Ecto.Changeset{} = Accounts.change_repository(repository)
    end
  end

  describe "collaborations" do
    alias Efossils.Accounts.Collaboration

    @valid_attrs %{mode: 42}
    @update_attrs %{mode: 43}
    @invalid_attrs %{mode: nil}

    def collaboration_fixture(attrs \\ %{}) do
      {:ok, collaboration} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_collaboration()

      collaboration
    end

    test "list_collaborations/0 returns all collaborations" do
      collaboration = collaboration_fixture()
      assert Accounts.list_collaborations() == [collaboration]
    end

    test "get_collaboration!/1 returns the collaboration with given id" do
      collaboration = collaboration_fixture()
      assert Accounts.get_collaboration!(collaboration.id) == collaboration
    end

    test "create_collaboration/1 with valid data creates a collaboration" do
      assert {:ok, %Collaboration{} = collaboration} = Accounts.create_collaboration(@valid_attrs)
      assert collaboration.mode == 42
    end

    test "create_collaboration/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_collaboration(@invalid_attrs)
    end

    test "update_collaboration/2 with valid data updates the collaboration" do
      collaboration = collaboration_fixture()
      assert {:ok, collaboration} = Accounts.update_collaboration(collaboration, @update_attrs)
      assert %Collaboration{} = collaboration
      assert collaboration.mode == 43
    end

    test "update_collaboration/2 with invalid data returns error changeset" do
      collaboration = collaboration_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_collaboration(collaboration, @invalid_attrs)
      assert collaboration == Accounts.get_collaboration!(collaboration.id)
    end

    test "delete_collaboration/1 deletes the collaboration" do
      collaboration = collaboration_fixture()
      assert {:ok, %Collaboration{}} = Accounts.delete_collaboration(collaboration)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_collaboration!(collaboration.id) end
    end

    test "change_collaboration/1 returns a collaboration changeset" do
      collaboration = collaboration_fixture()
      assert %Ecto.Changeset{} = Accounts.change_collaboration(collaboration)
    end
  end

  describe "collaborations" do
    alias Efossils.Accounts.Collaboration

    @valid_attrs %{fossil_password: "some fossil_password", fossil_username: "some fossil_username", mode: "some mode"}
    @update_attrs %{fossil_password: "some updated fossil_password", fossil_username: "some updated fossil_username", mode: "some updated mode"}
    @invalid_attrs %{fossil_password: nil, fossil_username: nil, mode: nil}

    def collaboration_fixture(attrs \\ %{}) do
      {:ok, collaboration} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_collaboration()

      collaboration
    end

    test "list_collaborations/0 returns all collaborations" do
      collaboration = collaboration_fixture()
      assert Accounts.list_collaborations() == [collaboration]
    end

    test "get_collaboration!/1 returns the collaboration with given id" do
      collaboration = collaboration_fixture()
      assert Accounts.get_collaboration!(collaboration.id) == collaboration
    end

    test "create_collaboration/1 with valid data creates a collaboration" do
      assert {:ok, %Collaboration{} = collaboration} = Accounts.create_collaboration(@valid_attrs)
      assert collaboration.fossil_password == "some fossil_password"
      assert collaboration.fossil_username == "some fossil_username"
      assert collaboration.mode == "some mode"
    end

    test "create_collaboration/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_collaboration(@invalid_attrs)
    end

    test "update_collaboration/2 with valid data updates the collaboration" do
      collaboration = collaboration_fixture()
      assert {:ok, collaboration} = Accounts.update_collaboration(collaboration, @update_attrs)
      assert %Collaboration{} = collaboration
      assert collaboration.fossil_password == "some updated fossil_password"
      assert collaboration.fossil_username == "some updated fossil_username"
      assert collaboration.mode == "some updated mode"
    end

    test "update_collaboration/2 with invalid data returns error changeset" do
      collaboration = collaboration_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_collaboration(collaboration, @invalid_attrs)
      assert collaboration == Accounts.get_collaboration!(collaboration.id)
    end

    test "delete_collaboration/1 deletes the collaboration" do
      collaboration = collaboration_fixture()
      assert {:ok, %Collaboration{}} = Accounts.delete_collaboration(collaboration)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_collaboration!(collaboration.id) end
    end

    test "change_collaboration/1 returns a collaboration changeset" do
      collaboration = collaboration_fixture()
      assert %Ecto.Changeset{} = Accounts.change_collaboration(collaboration)
    end
  end

  describe "collaborations" do
    alias Efossils.Accounts.Collaboration

    @valid_attrs %{capabilities: "some capabilities", fossil_password: "some fossil_password", fossil_username: "some fossil_username"}
    @update_attrs %{capabilities: "some updated capabilities", fossil_password: "some updated fossil_password", fossil_username: "some updated fossil_username"}
    @invalid_attrs %{capabilities: nil, fossil_password: nil, fossil_username: nil}

    def collaboration_fixture(attrs \\ %{}) do
      {:ok, collaboration} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_collaboration()

      collaboration
    end

    test "list_collaborations/0 returns all collaborations" do
      collaboration = collaboration_fixture()
      assert Accounts.list_collaborations() == [collaboration]
    end

    test "get_collaboration!/1 returns the collaboration with given id" do
      collaboration = collaboration_fixture()
      assert Accounts.get_collaboration!(collaboration.id) == collaboration
    end

    test "create_collaboration/1 with valid data creates a collaboration" do
      assert {:ok, %Collaboration{} = collaboration} = Accounts.create_collaboration(@valid_attrs)
      assert collaboration.capabilities == "some capabilities"
      assert collaboration.fossil_password == "some fossil_password"
      assert collaboration.fossil_username == "some fossil_username"
    end

    test "create_collaboration/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_collaboration(@invalid_attrs)
    end

    test "update_collaboration/2 with valid data updates the collaboration" do
      collaboration = collaboration_fixture()
      assert {:ok, collaboration} = Accounts.update_collaboration(collaboration, @update_attrs)
      assert %Collaboration{} = collaboration
      assert collaboration.capabilities == "some updated capabilities"
      assert collaboration.fossil_password == "some updated fossil_password"
      assert collaboration.fossil_username == "some updated fossil_username"
    end

    test "update_collaboration/2 with invalid data returns error changeset" do
      collaboration = collaboration_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_collaboration(collaboration, @invalid_attrs)
      assert collaboration == Accounts.get_collaboration!(collaboration.id)
    end

    test "delete_collaboration/1 deletes the collaboration" do
      collaboration = collaboration_fixture()
      assert {:ok, %Collaboration{}} = Accounts.delete_collaboration(collaboration)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_collaboration!(collaboration.id) end
    end

    test "change_collaboration/1 returns a collaboration changeset" do
      collaboration = collaboration_fixture()
      assert %Ecto.Changeset{} = Accounts.change_collaboration(collaboration)
    end
  end

  describe "stars" do
    alias Efossils.Accounts.Star

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def star_fixture(attrs \\ %{}) do
      {:ok, star} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_star()

      star
    end

    test "list_stars/0 returns all stars" do
      star = star_fixture()
      assert Accounts.list_stars() == [star]
    end

    test "get_star!/1 returns the star with given id" do
      star = star_fixture()
      assert Accounts.get_star!(star.id) == star
    end

    test "create_star/1 with valid data creates a star" do
      assert {:ok, %Star{} = star} = Accounts.create_star(@valid_attrs)
    end

    test "create_star/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_star(@invalid_attrs)
    end

    test "update_star/2 with valid data updates the star" do
      star = star_fixture()
      assert {:ok, star} = Accounts.update_star(star, @update_attrs)
      assert %Star{} = star
    end

    test "update_star/2 with invalid data returns error changeset" do
      star = star_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_star(star, @invalid_attrs)
      assert star == Accounts.get_star!(star.id)
    end

    test "delete_star/1 deletes the star" do
      star = star_fixture()
      assert {:ok, %Star{}} = Accounts.delete_star(star)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_star!(star.id) end
    end

    test "change_star/1 returns a star changeset" do
      star = star_fixture()
      assert %Ecto.Changeset{} = Accounts.change_star(star)
    end
  end
end
