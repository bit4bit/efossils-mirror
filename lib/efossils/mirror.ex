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

defmodule Efossils.Mirror do
  @moduledoc """
  Sincroniza repositorios
  """
  use GenServer

  @ticktime 60_000
  alias Efossils.Repo
  alias Efossils.Repositories
  alias Efossils.Accounts

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :tick, @ticktime)
    {:ok, %{}}
  end

  def handle_info(:tick, state) do
    spull = Enum.map(Repo.all(Repositories.PushMirror) |> Repo.preload([:repository]), fn(pushmirror) ->
      unless Map.has_key?(state, pushmirror.id) do
        {:ok, pid} = Efossils.MirrorPush.start_link(pushmirror)
        Process.monitor(pid)
        {pid, pushmirror}
      else
        nil
      end
    end)
    |> Enum.reject(&(is_nil(&1)))

    spush = Enum.map(Accounts.list_repositories_mirror(), fn(repository) ->
      unless Map.has_key?(state, repository.id) do
        if repository.is_mirror do
          {:ok, pid} = Efossils.MirrorPull.start_link(repository)
          Process.monitor(pid)
          {pid, repository}
        else
          nil
        end
      else
        nil
      end
    end)
    |> Enum.reject(&(is_nil(&1)))

    
    state = Enum.reduce(spull ++ spush, state, fn ({key, val}, state) ->
      Map.put(state, key, val)
    end)

    Process.send_after(self(), :tick, @ticktime)
    {:noreply, state}
  end
  
  def handle_info({:DOWN, _, :process, pid, _reason}, state) do
    {_, state} =  Map.pop(state, pid)
    {:noreply, state}
  end
end



defmodule Efossils.MirrorPull do
  use GenServer


  def start_link(repository) do
    GenServer.start_link(__MODULE__, repository)
  end

  def init(repository) do
    GenServer.cast(self(), :sync)
    {:ok, repository}
  end

  def handle_cast(:sync, repository) do
    do_pull(repository)
    {:stop, :normal, repository}
  end

  defp do_pull(%Efossils.Accounts.Repository{source: "fossil", is_mirror: true} = repository) do
    {:ok, ctx} = Efossils.Accounts.context_repository(repository)
    # TODO: donde informar?
    {:ok, _} = Efossils.Command.pull(ctx, repository.clone_url)
  end
  defp do_pull(_), do: nil
end

defmodule Efossils.MirrorPush do
  use GenServer

  def start_link(pushmirror) do
    GenServer.start_link(__MODULE__, pushmirror)
  end

  def init(pushmirror) do
    GenServer.cast(self(), :sync)
    {:ok, %{pushmirror: pushmirror}}
  end

  def handle_cast(:sync, %{pushmirror: pushmirror} = state) do
    do_push(pushmirror)
    {:stop, :normal, state}
  end

  defp do_push(%Efossils.Repositories.PushMirror{source: "git"} = pushmirror) do
    {:ok, ctx} = Efossils.Accounts.context_repository(pushmirror.repository)
    case Efossils.Command.git_export(ctx, pushmirror.url) do
      {:ok, _} ->
        {:ok, _} = Efossils.Repositories.update_push_mirror(pushmirror,
        %{"last_sync": DateTime.utc_now(), "last_sync_status": "ok" })
      {:error, _} ->
        {:ok, _} = Efossils.Repositories.update_push_mirror(pushmirror,
        %{"last_sync": DateTime.utc_now(), "last_sync_status": "failed" })
    end
  end
  defp do_push(%Efossils.Repositories.PushMirror{source: "fossil"} = pushmirror) do
    {:ok, ctx} = Efossils.Accounts.context_repository(pushmirror.repository)
    case Efossils.Command.push(ctx, pushmirror.url) do
      {:ok, _} ->
        {:ok, _} = Efossils.Repositories.update_push_mirror(pushmirror,
        %{"last_sync": DateTime.utc_now(), "last_sync_status": "ok" })
      {:error, _} ->
        {:ok, _} = Efossils.Repositories.update_push_mirror(pushmirror,
        %{"last_sync": DateTime.utc_now(), "last_sync_status": "failed" })
    end
  end
end
