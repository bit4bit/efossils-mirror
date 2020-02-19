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

  @ticktime Application.get_env(:efossils, :fossil_mirror_ticktime)
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
    values = Map.keys(state)
    
    spull = Enum.map(Repo.all(Repositories.PushMirror) |> Repo.preload([:repository]), fn(pushmirror) ->
      unless pushmirror.repository_id in values do
        {:ok, pid} = Efossils.MirrorPush.start_link(pushmirror)
        Process.monitor(pid)
        {pid, pushmirror.repository_id}
      else
        nil
      end
    end)
    |> Enum.reject(&(is_nil(&1)))

    spush = Enum.map(Accounts.list_repositories_mirror(), fn(repository) ->
      unless repository.id in values do
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
    {:ok, %{repo: repository, timeout: 60_000}}
  end

  def handle_cast(:sync, %{repo: repository} = state) do
    do_sync(repository, state)
  end

  def handle_info(:sync, %{repo: repository} = state) do
    do_sync(repository, state)
  end

  defp do_sync(repository, %{timeout: timeout} = state) do
    case do_pull(repository) do
      :ok ->
        {:stop, :normal, state}
      :locked ->
        Process.send_after(self(), :sync, timeout)
        state = Map.put(state, :timeout, timeout + 60_000)
        {:noreply, state}
    end
  end

  defp do_pull(%Efossils.Accounts.Repository{source: "fossil", is_mirror: true} = repository) do
    {:ok, ctx} = Efossils.Accounts.context_repository(repository)
    # TODO: donde informar?
    case Efossils.Command.pull(ctx, repository.clone_url) do
      {:ok, _} ->
        :ok
      {:error, reason} ->
        if String.contains?(reason, "database is locked") do
          :locked
        else
          raise reason
        end
    end
  end
  defp do_pull(_), do: :ok
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
    case Efossils.Command.git_export(ctx, Integer.to_string(pushmirror.id), pushmirror.url) do
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
