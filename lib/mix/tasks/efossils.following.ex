defmodule Mix.Tasks.Efossils.Following do
  use Mix.Task
  @shortdoc "following instances"

  alias Efossils.Repo
  alias Efossils.Accounts
  alias Efossils.ActivityPub

  def run(_) do
    Mix.Task.run("app.start")
    print_following(Repo.all(ActivityPub.Follow))
  end


  defp print_following([follow | rest]) do
    actor = ActivityPub.Vocabulary.Actor.cast(follow.actor)
    Mix.Shell.IO.info(actor.id)
    print_following(rest)
  end
  defp print_following([]) do
  end
end
