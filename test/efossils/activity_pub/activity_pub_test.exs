defmodule Efossils.ActivityPubTest do
  use Efossils.DataCase

  alias Efossils.ActivityPub

  describe "follows" do
    alias Efossils.ActivityPub.Follow

    @valid_attrs %{ap_id: "some ap_id", banned: true}
    @update_attrs %{ap_id: "some updated ap_id", banned: false}
    @invalid_attrs %{ap_id: nil, banned: nil}

    def follow_fixture(attrs \\ %{}) do
      {:ok, follow} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ActivityPub.create_follow()

      follow
    end

    test "list_follows/0 returns all follows" do
      follow = follow_fixture()
      assert ActivityPub.list_follows() == [follow]
    end

    test "get_follow!/1 returns the follow with given id" do
      follow = follow_fixture()
      assert ActivityPub.get_follow!(follow.id) == follow
    end

    test "create_follow/1 with valid data creates a follow" do
      assert {:ok, %Follow{} = follow} = ActivityPub.create_follow(@valid_attrs)
      assert follow.ap_id == "some ap_id"
      assert follow.banned == true
    end

    test "create_follow/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ActivityPub.create_follow(@invalid_attrs)
    end

    test "update_follow/2 with valid data updates the follow" do
      follow = follow_fixture()
      assert {:ok, %Follow{} = follow} = ActivityPub.update_follow(follow, @update_attrs)
      assert follow.ap_id == "some updated ap_id"
      assert follow.banned == false
    end

    test "update_follow/2 with invalid data returns error changeset" do
      follow = follow_fixture()
      assert {:error, %Ecto.Changeset{}} = ActivityPub.update_follow(follow, @invalid_attrs)
      assert follow == ActivityPub.get_follow!(follow.id)
    end

    test "delete_follow/1 deletes the follow" do
      follow = follow_fixture()
      assert {:ok, %Follow{}} = ActivityPub.delete_follow(follow)
      assert_raise Ecto.NoResultsError, fn -> ActivityPub.get_follow!(follow.id) end
    end

    test "change_follow/1 returns a follow changeset" do
      follow = follow_fixture()
      assert %Ecto.Changeset{} = ActivityPub.change_follow(follow)
    end
  end
end
