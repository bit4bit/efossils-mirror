defmodule Efossils.Http do
  @moduledoc """
  Abre tunnel a comando *fossil http*
  """
  alias Efossils.Command
  
  @spec ephimeral(Command.context(), String.t) :: String.t
  def ephimeral(ctx, baseurl) do
    {:ok, socket} = :gen_tcp.listen(0,
      [:binary, packet: :raw, active: :false, reuseaddr: true])
    {:ok, port} = :inet.port(socket)
    spawn(fn -> loop(socket, ctx, baseurl) end)
    "http://127.0.0.1:#{port}"
  end

  defp loop(socket, ctx, baseurl) do
    pid = self()
    db_path = Keyword.get(ctx, :db_path)
    username =  Keyword.get(ctx, :default_username)
    env = [{"HOME", Keyword.get(ctx, :work_path)},
           {"FOSSIL_USER", username},
           {"REMOTE_USER", username}]
    proc = %Porcelain.Process{:err => nil} = Porcelain.spawn(Command.get_command, ["http", "--nossl", "--baseurl", baseurl, db_path], [in: :receive, out: {:send, pid}, env: env])
    {:ok, client} = :gen_tcp.accept(socket)
    :ok = :gen_tcp.controlling_process(client, self())
    serve(socket, client, proc)
  end

  defp serve(socket, client, proc) do
    :inet.setopts(client, active: :once)
    %Porcelain.Process{pid: pid} = proc

    receive do
      {:tcp, client, data} ->
        Porcelain.Process.send_input(proc, data)
        serve(socket, client, proc)
      {:tcp_closed, _} ->
        Porcelain.Process.signal(proc, :kill)
      {^pid, :data, :out, data} ->
        :gen_tcp.send(client, data)
        serve(socket, client, proc)
      {^pid, :data, :err, err} ->
        raise inspect err
      {^pid, :result, _result} ->
        :gen_tcp.close(socket)
        Porcelain.Process.signal(proc, :kill)
      any -> raise inspect any
    after
      5_000 ->
        :gen_tcp.close(socket)
        Porcelain.Process.signal(proc, :kill)
    end
  end
end
