defmodule Efossils.RepositoriesTest do
  use Efossils.DataCase

  alias Efossils.Repositories

  describe "push_mirrors" do
    alias Efossils.Repositories.PushMirror

    @valid_attrs %{source: "some source", url: "some url"}
    @update_attrs %{source: "some updated source", url: "some updated url"}
    @invalid_attrs %{source: nil, url: nil}

    def push_mirror_fixture(attrs \\ %{}) do
      {:ok, push_mirror} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Repositories.create_push_mirror()

      push_mirror
    end

    test "list_push_mirrors/0 returns all push_mirrors" do
      push_mirror = push_mirror_fixture()
      assert Repositories.list_push_mirrors() == [push_mirror]
    end

    test "get_push_mirror!/1 returns the push_mirror with given id" do
      push_mirror = push_mirror_fixture()
      assert Repositories.get_push_mirror!(push_mirror.id) == push_mirror
    end

    test "create_push_mirror/1 with valid data creates a push_mirror" do
      assert {:ok, %PushMirror{} = push_mirror} = Repositories.create_push_mirror(@valid_attrs)
      assert push_mirror.source == "some source"
      assert push_mirror.url == "some url"
    end

    test "create_push_mirror/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Repositories.create_push_mirror(@invalid_attrs)
    end

    test "update_push_mirror/2 with valid data updates the push_mirror" do
      push_mirror = push_mirror_fixture()
      assert {:ok, %PushMirror{} = push_mirror} = Repositories.update_push_mirror(push_mirror, @update_attrs)
      assert push_mirror.source == "some updated source"
      assert push_mirror.url == "some updated url"
    end

    test "update_push_mirror/2 with invalid data returns error changeset" do
      push_mirror = push_mirror_fixture()
      assert {:error, %Ecto.Changeset{}} = Repositories.update_push_mirror(push_mirror, @invalid_attrs)
      assert push_mirror == Repositories.get_push_mirror!(push_mirror.id)
    end

    test "delete_push_mirror/1 deletes the push_mirror" do
      push_mirror = push_mirror_fixture()
      assert {:ok, %PushMirror{}} = Repositories.delete_push_mirror(push_mirror)
      assert_raise Ecto.NoResultsError, fn -> Repositories.get_push_mirror!(push_mirror.id) end
    end

    test "change_push_mirror/1 returns a push_mirror changeset" do
      push_mirror = push_mirror_fixture()
      assert %Ecto.Changeset{} = Repositories.change_push_mirror(push_mirror)
    end
  end
end
