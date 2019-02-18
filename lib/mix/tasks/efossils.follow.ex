defmodule Mix.Tasks.Efossils.Follow do
  use Mix.Task

  @shortdoc "follow a instance"
  def run([ap_id]) do
    Mix.Task.run("app.start")
    case EfossilsWeb.Utils.ap_follow(ap_id) do
      {:ok, resp} ->
        Mix.Shell.IO.info(resp)
      {:error, error} ->
        IO.puts(error)
        Mix.Shell.IO.error(error)
    end
  end
end
