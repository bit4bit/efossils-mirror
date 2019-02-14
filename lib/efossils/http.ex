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

defmodule Efossils.HttpSingleRequest do
  use GenServer
  alias Efossils.Command

  def start(ctx, method, baseurl, remote_url, headers, body) do
    GenServer.start(__MODULE__, [ctx, method, baseurl, remote_url, headers, body])
  end

  def init([ctx, method, baseurl, remote_url, headers, body]) do
    db_path = Keyword.get(ctx, :db_path)
    username =  Keyword.get(ctx, :default_username)
    env = [{'HOME', to_charlist(Keyword.get(ctx, :work_path))},
           {'SSH_CONNECTION', ''},
           {'FOSSIL_USER', to_charlist(username)},
           {'REMOTE_USER', to_charlist(username)}]
    args = ["http", "--nossl",
            "-U", username,
            "--https",
            "--baseurl", "#{baseurl}",
            db_path]
    path = System.find_executable(Command.get_command)
    port = Port.open({:spawn_executable, path}, [:binary, :eof, args: args, env: env])
    Port.command(port, "#{method} #{remote_url} HTTP/1.1\r\n")
    Enum.each(headers, fn ({key, val}) ->
      Port.command(port, "#{key}: #{val}\r\n")
    end)
    Port.command(port, "\r\n")
    Port.command(port, body)
    {:ok, {port, nil, ""}}
  end

  def response(pid) do
    GenServer.call(pid, :body)
  end

  def response_decode(response) do
    [header, body] = String.split(response, "\r\n\r\n", parts: 2)
    {:ok, {:http_response, _, status_code, _}, header_rest} = :erlang.decode_packet(:http, header, [])
    headers = decode_headers(header_rest <> "\r\n\r\n", [])
    {:ok, {body, headers, status_code}}
  end
  
  defp decode_headers(data, headers) do
    case :erlang.decode_packet(:httph, data, []) do
      {:ok, {:http_header, _, key, _, value}, rest} ->
        headers1 = headers ++ [{to_string(key), to_string(value)}]
        decode_headers(rest, headers1)
      {:ok, :http_eoh, _} ->
        headers
    end
  end

  def handle_call(:body, from, {port, _from, acc}) do
    {:noreply, {port, from, acc}}
  end

  def handle_info({port, {:data, data}}, {port, from, acc}) do
    {:noreply, {port, from, acc <> data}}
  end

  def handle_info({port, :closed}, {port, from, acc} = state) do
    GenServer.reply(from, {:ok, acc})
    {:stop, :normal, state}
  end
  def handle_info({port, :eof}, {port, from, acc} = state) do
    GenServer.reply(from, {:ok, acc})
    {:stop, :normal, state}
  end

  def handle_info({:EXIT, port, reason}, {port, from, acc} = state) do
    GenServer.reply(from, {:ok, acc})
    {:stop, :normal, state}
  end
end

defmodule Efossils.Http do
  @moduledoc """
  Abre tunnel a comando *fossil http*
  """
  use GenServer
  alias Efossils.Command

  @timeout_server_seconds 360
  @server_tick_time 60_000
  
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    {:ok, {%{}, %{}}}
  end

  def single_request(ctx, method, baseurl, remote_url, headers, body) do
    {:ok, pid} = Efossils.HttpSingleRequest.start(ctx, method, baseurl, remote_url, headers, body)
    {:ok, resp} = Efossils.HttpSingleRequest.response(pid)
    Efossils.HttpSingleRequest.response_decode(resp)
  end

  def terminate(_reason, {by_pid, _} = state) do
    Enum.each(by_pid, fn {pid, server} ->
      Porcelain.Process.signal(server[:proc], :kill)
    end)
    :shutdown
  end
  
  @spec ephimeral(Command.context(), String.t, boolean) :: String.t
  def ephimeral(ctx, baseurl, is_xfer \\ false) do
    GenServer.call(__MODULE__, {:ephimeral, ctx, baseurl, is_xfer})
  end


  def handle_call({:ephimeral, ctx, baseurl, is_xfer}, from, {by_pid, by_uid} = state) do
    #se reusa servidor inicialido ya que los /xfer son para el mismo repositorio
    uid = case is_xfer do
            false -> uid_server(ctx)
            true ->
              db_path = Keyword.get(ctx, :db_path)
              uids = Enum.filter(Map.keys(by_uid), fn key ->
                String.contains?(key, db_path)
              end)

              case List.first(uids) do
                nil -> uid_server(ctx)
                uid -> uid
              end
          end
    
    case by_uid[uid] do
      nil ->
        proc = spawn_server(ctx, baseurl)
        data = %{url: nil, proc: proc, from: from, uid: uid}
        by_pid = Map.put(by_pid, proc.pid, data)
        by_uid = Map.put(by_uid, uid, %{:url => nil,
                                        :time => System.system_time(:seconds)
                                       })
        {:noreply, {by_pid, by_uid}}
      item ->
        by_uid = Map.put(by_uid, uid, %{by_uid[uid] | time: System.system_time(:seconds)})

        {:reply, item[:url], {by_pid, by_uid}}
    end
  end

  def stream_output(port, acc) do
    receive do
      {port, {:data, data}} ->
        acc = acc <> data
        stream_output(port, acc)
      {port, :closed} ->
        :close
      {:EXIT, port, reason} ->
        {:error, reason}
    end
  end

  defp spawn_server(ctx, baseurl) do
    db_path = Keyword.get(ctx, :db_path)
    username =  Keyword.get(ctx, :default_username)
    env = [{"HOME", Keyword.get(ctx, :work_path)},
           {"FOSSIL_USER", username},
           {"REMOTE_USER", username}]
    %Porcelain.Process{:err => nil} = Porcelain.spawn(Command.get_command, ["server", "--nossl",
                                                                            "--localhost",
                                                                            "--https",
                                                                            "--baseurl", baseurl, db_path],
      [in: :receive, out: {:send, self()}, env: env])
  end

  defp uid_server(ctx) do
    db_path = Keyword.get(ctx, :db_path)
    username = Keyword.get(ctx, :default_username)
    "#{db_path}_#{username}"
  end


  def handle_info({pid, :data, :out, <<"Listening for HTTP requests on TCP port ", port::binary>>},
    {by_pid, by_uid} = state) do
    server = by_pid[pid]
    uid = server[:uid]
    url =  String.trim("http://127.0.0.1:#{port}")
    GenServer.reply(server[:from], url)
    by_uid = Map.put(by_uid, uid, %{by_uid[uid] | url: url})
    
    Process.send_after(self(), {:server_tick, pid}, @server_tick_time)
    {:noreply, {by_pid, by_uid}}
  end

  def handle_info({pid, :result, _result}, {by_pid, by_uid} = state) do
    case by_pid[pid] do
      nil -> {:noreply, state}
      server ->
        by_pid = Map.delete(by_pid, pid)
        by_uid = Map.delete(by_uid, server[:uid])
        {:noreply, {by_pid, by_uid}}
    end
  end

  def handle_info({pid, :data, :err, _err}, {by_pid, by_uid} = state) do
    case by_pid[pid] do
      nil -> {:noreply, state}
      server ->
        Porcelain.Process.signal(server[:proc], :kill)
        by_pid = Map.delete(by_pid, pid)
        {:noreply, by_pid}
    end
  end

  def handle_info({:server_tick, pid}, {by_pid, by_uid} = state) do
    case by_pid[pid] do
      nil -> {:noreply, state}
      server ->
        uid = server[:uid]
        now = System.system_time(:seconds)
        diff = now - by_uid[uid][:time]
        if  diff > @timeout_server_seconds do
                 Porcelain.Process.signal(server[:proc], :kill)
                 {:noreply, {by_pid, by_uid}}
                 else
                   Process.send_after(self(), {:server_tick, pid}, @server_tick_time)
                   {:noreply, {by_pid, by_uid}}
        end
    end
  end
end
