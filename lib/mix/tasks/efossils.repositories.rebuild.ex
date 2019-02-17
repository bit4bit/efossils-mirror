defmodule Mix.Tasks.Efossils.Repositories.Rebuild do
  use Mix.Task

  @shortdoc "rebuild repositories"

  def run(_) do
    Mix.Task.run("app.start")
    Enum.each(Efossils.Accounts.list_repositories(), &rebuild/1)
  end

  defp rebuild(repository) do
    {:ok, ctx} = Efossils.Accounts.context_repository(repository)
    Efossils.Command.rebuild(ctx)
  end
end
