defmodule Efossils.Command do
  require Logger
  
  @command "fossil"
  
  @repositories_path Path.absname(Application.get_env(:efossils, :fossil_repositories_path))
  @work_path Path.absname(Application.get_env(:efossils, :fossil_work_path))
  @username_admin Application.get_env(:efossils, :fossil_user_admin)

  @type context :: any()
  
  
  defp start_fossil_pool() do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  defp get_db_path_from_pool(db_path) do
    Agent.get(__MODULE__, fn map ->
      Map.get(map, db_path)
    end)
  end
  
  defp get_fossil_url_from_pool(ctx, baseurl) do
    db_path = Keyword.get(ctx, :db_path)
    
    case get_db_path_from_pool(db_path) do
      nil ->
        # TODO: el proceso queda activo aunque se detenga la plataforma
        %Porcelain.Process{err: nil, out: stream} = Porcelain.spawn(@command, ["server", "--baseurl", baseurl, db_path], [out: :stream])
        ["Listening for HTTP requests on TCP port " <> ports] = Enum.take(stream, 1)
        {port, _} = Integer.parse(ports)
        url = "http://127.0.0.1:#{port}"
        Agent.update(__MODULE__, &Map.put(&1, db_path, url))
        url
      url -> url
    end
  end

  @doc """
  Inicializa un repositorio
  """
  @spec init_repository(String.t, String.t):: {:ok, String.t} | {:error, String.t}
  def init_repository(name, group) do
    start_fossil_pool()
    
    priv_path = Application.app_dir(:efossils, "priv")
    group_path = Path.join([priv_path, @repositories_path, group])
    File.mkdir_p!(group_path)
    work_path = Path.join([priv_path, @work_path, group, name])
    File.mkdir_p!(work_path)
    db_path = Path.join([group_path, "#{name}.fossil"])
    
    ctx = [db_path: db_path,
           work_path: work_path,
           group_path: group_path,
           default_username: @username_admin,
          ]
    case cmd(ctx, ["init", db_path]) do
      {stdout, 0} ->
        if String.contains?(stdout, "admin-user") do
          {:ok, ctx}
        else
          {:error, stdout}
        end
      {"file already exists" <> _rest, _} ->
        {:ok, ctx}
      {stdout, _} ->
        {:error, stdout}
    end
  end

  @doc """
  Crea un nuevo usuario en repositorio.
  Se utiliza `contact_info` como `id` de relacion, con plataforma.
  """
  @spec new_user(context(), String.t, String.t|integer, String.t) :: {:ok, context()} | {:error, String.t}
  def new_user(ctx, username, id, password) when is_integer(id) do
    ids = Integer.to_string(id)
    new_user(ctx, username, ids, password)
  end
  def new_user(ctx, username, contact_info, password) do
    case cmd(ctx, ["user", "new", "-R", Keyword.get(ctx, :db_path),
              username, contact_info, password]) do
      {_stdout, 0} ->
        {:ok, ctx}
      {stdout, 1} ->
        if String.contains?(stdout, "already exists") do
          {:ok, ctx}
        else
          {:error, stdout}
        end
      {stdout, _} ->
        {:error, stdout}
    end
  end

  @doc """
  Actualiza contrasena de usuario
  """
  @spec password_user(context(), String.t, String.t):: {:ok, context()} | {:error, :user_not_exists} | {:error, String.t}
  def password_user(ctx, username, newpassword) do
    case cmd(ctx, ["user", "password", "-R",
                   Keyword.get(ctx, :db_path),
                   username, newpassword]) do
      {_, 0} ->
        {:ok, ctx}
      {"no such user:" <> _rest, _} ->
        {:error, :user_not_exists}
      {stdout, _} ->
        {:error, stdout}
    end
  end

  def request_http(ctx, baseurl, url) do
    db_path = Keyword.get(ctx, :db_path)
    fossil_url = get_fossil_url_from_pool(ctx, baseurl)
    remote_url = fossil_url <> url
    HTTPoison.get(remote_url)
  end

  defp cmd(ctx, args, opts \\ []) do
    env = [{"HOME", Keyword.get(ctx, :work_path)},
           {"USER", Keyword.get(ctx, :default_username)}]
    System.cmd("fossil", args, [stderr_to_stdout: true, env: env] ++ opts)
  end
end
