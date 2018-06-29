defmodule EfossilsWeb.Utils do
  def fossil_path(rest, user, repo) do
    "/fossil/user/#{user.lower_name}/repository/#{repo.lower_name}/#{rest}"
  end
end
