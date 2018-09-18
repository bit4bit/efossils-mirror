defmodule Efossils.Command.Collaborative do
  @moduledoc false

  alias Efossils.Command
  
  def init(ctx) do
    #se implementa en priv/fossil.ticket.skin
    {:ok, ctx}
  end

  def append_assigned_to(ctx, username) do
    {:ok, ticket_common} = Command.db_config_get(ctx, "ticket-common")
    IO.puts inspect ticket_common
    case assigned_choices_parse(ticket_common) do
      [] -> {:error, :parser}
      users ->
        users_appended = ["set assigned_choices {"] ++
          Enum.map(users, &("  #{&1}")) ++ ["  #{username}"] ++ [""] #} al reemplazar
        s_users = Enum.join(users_appended, "\r\n")
        out = Regex.replace(~r/set assigned_choices *\{[^\}]+/, ticket_common, s_users)
        |> String.trim
        Command.db_config_set(ctx, "ticket-common", out)
    end
  end

  def remove_assigned_to(ctx, username) do
    {:ok, ticket_common} = Command.db_config_get(ctx, "ticket-common")

    case assigned_choices_parse(ticket_common) do
      [] -> {:error, :parser}
      users ->
        users_without_username = Enum.filter(users, &(&1 !== username))
        users_appended = ["set assigned_choices {"] ++
          Enum.map(users_without_username, &("  #{&1}")) ++ [""] #} al reemplazar
        s_users = Enum.join(users_appended, "\r\n")
        out = Regex.replace(~r/set assigned_choices *\{[^\}]+/, ticket_common, s_users)
        |> String.trim
        Command.db_config_set(ctx, "ticket-common", out)
    end
  end

  defp assigned_choices_parse(data) do
    case Regex.scan(~r/set assigned_choices \{([^\}]+)\}/, data) do
      [] -> []
      data ->
        [match] = data
        List.last(match) |> String.trim("\r\n") |> String.split("\r\n") 
        |> Enum.map(fn line -> String.trim(line) |> String.trim("\r\n") end)
        |> Enum.filter(fn line ->
          String.length(line) != 0 and line != ""
        end)
        |> Enum.dedup
    end
  end
end
