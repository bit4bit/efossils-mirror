defmodule Mix.Tasks.Efossils.User.MaxRepoCreation do
  use Mix.Task

  @shortdoc "set limit of repositories"

  def run([username, max]) do
    Mix.Task.run("app.start")
    user = Efossils.Accounts.get_user_by_username!(username)
    changeset = Ecto.Changeset.cast(user, %{:max_repo_creation => max}, [:max_repo_creation])
    Efossils.Repo.update!(changeset)
  end

  def run([username]) do
    Mix.Task.run("app.start")
    user = Efossils.Accounts.get_user_by_username!(username)
    IO.puts(user.max_repo_creation)
  end
end
