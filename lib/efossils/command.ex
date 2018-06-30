defmodule Efossils.Command do
  @moduledoc """
  Interfaz para la gestión de repositorio via comando *fossil*.
  """
  require Logger
  
  @command "fossil"
  
  @repositories_path Path.absname(Application.get_env(:efossils, :fossil_repositories_path))
  @work_path Path.absname(Application.get_env(:efossils, :fossil_work_path))
  @username_admin Application.get_env(:efossils, :fossil_user_admin)
  @priv_path Application.app_dir(:efossils, "priv")
  @type context :: any()
  
  
  @doc """
  Inicializa un repositorio
  """
  @spec init_repository(String.t, String.t):: {:ok, context()} | {:error, String.t}
  def init_repository(name, group, opts \\ []) do
    start_fossil_pool()
    

    group_path = Path.join([@priv_path, @repositories_path, group])
    File.mkdir_p!(group_path)
    work_path = Path.join([@priv_path, @work_path, group, name])
    File.mkdir_p!(work_path)
    db_path = Path.join([group_path, "#{name}.fossil"])
    
    ctx = [db_path: db_path,
           work_path: work_path,
           group_path: group_path,
           default_username: Keyword.get(opts, :default_username, @username_admin),
          ]
    case cmd(ctx, ["init", db_path]) do
      {stdout, 0} ->
        if String.contains?(stdout, "admin-user") do
          {:ok, _} = force_setting(ctx, "http_authentication_ok", "1")
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

  @spec delete_repository(context()):: {:ok, context()} | {:error, File.posix()}
  def delete_repository(ctx) do
    case File.rm(Keyword.get(ctx, :db_path)) do
      :ok -> {:ok, ctx}
      err -> err
    end
  end
  
  @doc """
  Crea un nuevo usuario en repositorio, si el usuario ya existe actualiza contrasena del mismo.
  Se utiliza `contact_info` como `id` de relacion, con plataforma.
  
  """
  @spec new_user(context(), String.t, String.t|integer, String.t) :: {:ok, context()} | {:error, String.t}
  def new_user(ctx, username, id, password) when is_integer(id) do
    ids = Integer.to_string(id)
    new_user(ctx, username, ids, password)
  end
  def new_user(ctx, username, contact_info, password) when is_binary(contact_info) and is_binary(username) and is_binary(password) do
    case cmd(ctx, ["user", "new", "-R", Keyword.get(ctx, :db_path),
              username, contact_info, password]) do
      {_stdout, 0} ->
        {:ok, ctx}
      {stdout, 1} ->
        if String.contains?(stdout, "already exists") do
          password_user(ctx, username, password)
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

  @doc """
  Actualiza permisos para usuario
  """
  @spec capabilities_user(context(), String.t, String.t):: {:ok, context()} | {:error, :user_not_exists} | {:error, String.t}
  def capabilities_user(ctx, username, caps) do
    case cmd(ctx, ["user", "capabilities", "-R",
                   Keyword.get(ctx, :db_path),
                   username, caps]) do
      {_, 0} ->
        {:ok, ctx}
      {"no such user:" <> _rest, _} ->
        {:error, :user_not_exists}
      {stdout, 0} ->
        {:error, stdout}
    end
  end
  
  @doc """
  Realiza peticion HTTP a fossil server
  """
  @spec request_http(context(), {String.t, String.t}, String.t, String.t, String.t, Stream.t|map(), String.t):: {:ok, HTTPoison.Response.t} | {:error, HTTPoison.Error.t}
  def request_http(ctx, credentials, baseurl, method, url, body, content_type) do
    db_path = Keyword.get(ctx, :db_path)
    opts = case credentials do
             nil -> []
             credentials ->
               [hackney: [basic_auth: credentials]]
           end
    fossil_url = get_fossil_url_from_pool(ctx, baseurl)
    remote_url = fossil_url <> url
    method = case method do
               "GET" -> :get
               "POST" -> :post
               "PUT" -> :put
               "DELETE" -> :delete
             end
    HTTPoison.request(method, remote_url, body, [{"Content-Type", content_type}], opts)
  end

  @doc """
  Modifica parametro de configuracion directo en base de datos
  del repositorio.
  """
  @spec force_setting(context(), String.t, String.t):: :ok | {:error, String.t}
  def force_setting(ctx, key, val) do
    db_path = Keyword.get(ctx, :db_path)
    query = "INSERT OR REPLACE INTO config VALUES(\"#{key}\", \"#{val}\", now())"
    case cmd(ctx, ["sql",
                   "-R", db_path, query]) do
      {_, 0} ->
        {:ok, ctx}
      {stdout, _} ->
        {:error, stdout}
    end
  end

  def setting(ctx, key, val) do
    case cmd(ctx, ["settings",
                   "-R", Keyword.get(ctx, :db_path), key, val]) do
      {_, 0} ->
        {:ok, ctx}
      {"no such setting" <> _rest, _} ->
        {:error, :no_such_setting}
      {stdout, _} ->
        {:error, stdout}
    end
  end
  
  @spec config_import(context(), String.t) :: {:ok, context()} | {:error, :no_such_file} | {:error, String.t}
  def config_import(ctx, file) do
    abs_path = Path.join(@priv_path, file)
    case cmd(ctx, ["config", "-R", Keyword.get(ctx, :db_path),
                   "import", abs_path]) do
      {_, 0} ->
        {:ok, ctx}
      {"no such file" <> _rest, _} ->
        {:error, :no_such_file}
      {stdout, _} ->
        {:error, stdout}
    end
  end
  
  @spec timeline(context(), Calendar.date()):: %{Calendar.date() => [String.t]}:: {:ok, [{Calendar.date(), String.t}]} | {:error, String.t}
  def timeline(ctx, checkin) when is_binary(checkin) do
    db_path = Keyword.get(ctx, :db_path)
    case cmd(ctx, ["timeline", "-R", db_path, "-W", "0", "-n", "0", checkin]) do
      {stdout, 0} ->
        {:ok, {checkin, String.split(stdout, "\n", trim: true) |> tl}}
      {stdout, _} ->
        {:error, stdout}
    end
  end
  def timeline(ctx, date) do
    timeline(ctx, Date.to_string(date))
  end

  def last_day_timeline(ctx) do
    db_path = Keyword.get(ctx, :db_path)
    case cmd(ctx, ["timeline", "-R", db_path, "-W", "0"]) do
      {stdout, 0} ->
        series = Enum.map_reduce(String.split(stdout, "\n", trim: true), nil,
          fn line, last_date ->
            if String.starts_with?(line, "===") do
              date = String.replace(line, "=", "") |> String.trim()
              {{date, nil}, date}
            else
              {{last_date, String.trim(line)}, last_date}
            end
        end)
        |> elem(0)

        {last_date, nil} = List.first(series)
        timelines = Enum.filter(series |> tl, fn {date, line} -> date == last_date end)
        |> Enum.reduce([], fn {date, line}, acc ->
          acc ++ [line]
        end)
        # se elimina ultima linea
        |> Enum.reverse |> tl |> Enum.reverse
        {:ok, {last_date, timelines}}
      {stdout, _} ->
        {:error, stdout}
    end
  end
  
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
        %Porcelain.Process{err: nil, out: stream} = Porcelain.spawn(@command, ["server", "--nossl", "--baseurl", baseurl, db_path], [out: :stream])
        ["Listening for HTTP requests on TCP port " <> ports] = Enum.take(stream, 1)
        {port, _} = Integer.parse(ports)
        url = "http://127.0.0.1:#{port}"
        Agent.update(__MODULE__, &Map.put(&1, db_path, url))
        url
      url -> url
    end
  end

  defp cmd(ctx, args, opts \\ []) do
    env = [{"HOME", Keyword.get(ctx, :work_path)},
           {"USER", Keyword.get(ctx, :default_username)}]
    System.cmd("fossil", args, [stderr_to_stdout: true, env: env] ++ opts)
  end
end
