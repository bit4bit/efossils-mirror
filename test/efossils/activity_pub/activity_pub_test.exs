defmodule Efossils.ActivityPubTest do
  use Efossils.DataCase

  alias Efossils.ActivityPub

  describe "follows" do
    alias Efossils.ActivityPub.Follow

    @valid_attrs %{actor: "some actor", banned: true}
    @update_attrs %{actor: "some updated actor", banned: false}
    @invalid_attrs %{actor: nil, banned: nil}

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
      assert follow.actor == "some actor"
      assert follow.banned == true
    end

    test "create_follow/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ActivityPub.create_follow(@invalid_attrs)
    end

    test "update_follow/2 with valid data updates the follow" do
      follow = follow_fixture()
      assert {:ok, %Follow{} = follow} = ActivityPub.update_follow(follow, @update_attrs)
      assert follow.actor == "some updated actor"
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

  describe "notifications" do
    alias Efossils.ActivityPub.Notification

    @valid_attrs %{actor: %{}, rest: %{}, seen: true, type: "some type"}
    @update_attrs %{actor: %{}, rest: %{}, seen: false, type: "some updated type"}
    @invalid_attrs %{actor: nil, rest: nil, seen: nil, type: nil}

    def notification_fixture(attrs \\ %{}) do
      {:ok, notification} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ActivityPub.create_notification()

      notification
    end

    test "list_notifications/0 returns all notifications" do
      notification = notification_fixture()
      assert ActivityPub.list_notifications() == [notification]
    end

    test "get_notification!/1 returns the notification with given id" do
      notification = notification_fixture()
      assert ActivityPub.get_notification!(notification.id) == notification
    end

    test "create_notification/1 with valid data creates a notification" do
      assert {:ok, %Notification{} = notification} = ActivityPub.create_notification(@valid_attrs)
      assert notification.actor == %{}
      assert notification.rest == %{}
      assert notification.seen == true
      assert notification.type == "some type"
    end

    test "create_notification/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ActivityPub.create_notification(@invalid_attrs)
    end

    test "update_notification/2 with valid data updates the notification" do
      notification = notification_fixture()
      assert {:ok, %Notification{} = notification} = ActivityPub.update_notification(notification, @update_attrs)
      assert notification.actor == %{}
      assert notification.rest == %{}
      assert notification.seen == false
      assert notification.type == "some updated type"
    end

    test "update_notification/2 with invalid data returns error changeset" do
      notification = notification_fixture()
      assert {:error, %Ecto.Changeset{}} = ActivityPub.update_notification(notification, @invalid_attrs)
      assert notification == ActivityPub.get_notification!(notification.id)
    end

    test "delete_notification/1 deletes the notification" do
      notification = notification_fixture()
      assert {:ok, %Notification{}} = ActivityPub.delete_notification(notification)
      assert_raise Ecto.NoResultsError, fn -> ActivityPub.get_notification!(notification.id) end
    end

    test "change_notification/1 returns a notification changeset" do
      notification = notification_fixture()
      assert %Ecto.Changeset{} = ActivityPub.change_notification(notification)
    end
  end
end
