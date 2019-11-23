defmodule EfossilsWeb.EfossilsHelper do
  @moduledoc false
  alias Efossils.Accounts

  def repository_username(repo) do
    repo.owner.name
  end
  
  def repository_num_collaborators(repo) do
    Accounts.count_collaborations(repo)
  end
  
  def repository_last_day_timeline(repo) do
    {:ok, ctx} = Accounts.context_repository(repo)
    {:ok, {date, timeline}} = Efossils.Command.last_day_timeline(ctx, 5)
    repository_timeline_parse(repo, {date, timeline})
  end
  
  def repository_timeline(repo, date) do
    {:ok, ctx} = Accounts.context_repository(repo)
    {:ok, {date, timeline}} = Efossils.Command.timeline(ctx, date)
    repository_timeline_parse(repo, timeline)
  end

  defp repository_timeline_parse(repo, "") do
    []
  end
  defp repository_timeline_parse(repo, {date, timeline}) when is_list(timeline) do
    {date, Enum.map(timeline, &repository_timeline_parse(repo, &1))}
  end
  defp repository_timeline_parse(repo, timeline) when is_binary(timeline) do
    #http://localhost:4000/fossil/user/efossils_main/repository/mirepo/info/e763b40bb033437d
    [hour, commit, message] = String.split(timeline, " ", parts: 3)
    #commit = String.replace(racommit, ["[", "]"], "")
    %{
      "hour" => hour,
      "commit" => fossil_links_format(commit, repo),
      "message" => fossil_links_format(message, repo)
    }
  end

  defp fossil_links_format(data, repo) do
    data1 = Regex.replace(~r/\[(.+)\|(.+)\]/, data, fn _, v -> "[#{v}]" end)
    Regex.replace(~r/\[(.+)\]/, data1, fn _, v ->
      ~s|<a href="#{EfossilsWeb.Utils.fossil_path("info/#{v}", repo.owner, repo)}">[#{v}]</a>|
    end)
  end
end
