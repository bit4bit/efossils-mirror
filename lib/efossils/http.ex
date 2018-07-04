# Efossils -- a multirepository for fossil-scm
# Copyright (C) 2018  Jovany Leandro G.C <bit4bit@riseup.net>
#
# This file is part of Efossils.
#
# Efossils is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Efossils is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

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

    @spec ephimeral_port(Command.context(), String.t) :: integer()
  def ephimeral_port(ctx, baseurl) do
    {:ok, socket} = :gen_tcp.listen(0,
      [:binary, packet: :raw, active: :false, reuseaddr: true, ip: {127,0,0,1}])
    {:ok, port} = :inet.port(socket)
    spawn(fn -> loop(socket, ctx, baseurl) end)
    port
  end

  defp loop(socket, ctx, baseurl) do
    pid = self()
    db_path = Keyword.get(ctx, :db_path)
    username =  Keyword.get(ctx, :default_username)
    env = [{"HOME", Keyword.get(ctx, :work_path)},
           {"FOSSIL_USER", username},
           {"REMOTE_USER", username}]
    proc = %Porcelain.Process{:err => nil} = Porcelain.spawn(Command.get_command, ["http", "--nossl", "--baseurl", baseurl, db_path], [in: :receive, out: {:send, pid}, env: env])
    case  :gen_tcp.accept(socket, 50_000) do
      {:ok, client} ->
        :ok = :gen_tcp.controlling_process(client, self())
        serve(socket, client, proc)
      {:error, err} ->
        IO.puts inspect err
        Porcelain.Process.signal(proc, :kill)
    end
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
        IO.puts data
        :gen_tcp.send(client, data)
        serve(socket, client, proc)
      {^pid, :data, :err, err} ->
        IO.puts inspect err
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
