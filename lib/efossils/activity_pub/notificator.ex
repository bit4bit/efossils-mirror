defmodule Efossils.ActivityPub.Notificator do
  @moduledoc false

  use GenServer
  alias Efossils.ActivityPub
  alias Efossils.ActivityPub.Vocabulary
  alias Efossils.ActivityStreams
  alias Efossils.Repo

  @max_retries 3
  
  def start_link do
    GenServer.start_link(__MODULE__, %{retries: []}, name: __MODULE__)
  end

  def init(args) do
    Process.send_after(self(), :resend, 1000 * 30)
    {:ok, args}
  end

  def send(%ActivityStreams.Vocabulary.Activity{type: "Create"} = activity) do
    ActivityPub.list_follows
    |> Enum.each(fn follow ->
      actor = ActivityPub.Vocabulary.Actor.cast(follow.actor)
      inbox_url = ActivityPub.Vocabulary.Actor.first_inbox(actor)
      activity0 = Map.put(activity, :to, [actor.id])
      {:ok, notification} = ActivityPub.create_notification(%{
            url: inbox_url,
            type: "Create",
            content: ActivityStreams.render(activity0)})
      GenServer.cast(__MODULE__, {:send, notification, 0})
    end)
  end
  
  def send(%ActivityStreams.Vocabulary.Accept{actor: %Vocabulary.Actor{} = actor} = accept) do
    url = Vocabulary.Actor.first_inbox(actor)
    {:ok, notification} = ActivityPub.create_notification(%{url: url,
                                                            type: "Accept",
                                                            content: ActivityStreams.render(accept)})
    GenServer.cast(__MODULE__, {:send, notification, 0})
  end

  def handle_cast({:send, notification, retry}, %{retries: retries} = state) do
    case EfossilsWeb.Utils.post(notification.url, notification.content) do
      {:ok, _} ->
        ActivityPub.update_notification(notification, %{seen: true})
        {:noreply, state}
      {:error, _} ->
        if retry <= @max_retries do
          {:noreply, %{retries: retries ++ [{notification, retry + 1}]}}
        else
          {:noreply, state}
        end
    end
  end

  def handle_info(:resend, %{retries: retries}) do
    Enum.each(retries, fn {notification, retry} ->
      GenServer.cast(__MODULE__, {:send, notification, retry})
    end)

    Process.send_after(self(), :resend, 1000 * 30)
    {:noreply, %{retries: []}}
  end

end
