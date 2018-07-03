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

defmodule Efossils.Command do
  @moduledoc """
  Interfaz para la gestión de repositorio via comando *fossil*.
  """
  require Logger
  
  @priv_path Application.app_dir(:efossils, "priv")
  @type context :: any()
  
  
  @doc """
  Inicializa un repositorio
  """
  @spec init_repository(String.t, String.t):: {:ok, context()} | {:error, String.t}
  def init_repository(name, group, opts \\ []) do
    group_path = Path.join([get_repositories_path, group])
    File.mkdir_p!(group_path)
    work_path = Path.join([get_work_path, group, name])
    File.mkdir_p!(work_path)
    db_path = Path.join([group_path, "#{name}.fossil"])
    
    ctx = [db_path: db_path,
           work_path: work_path,
           group_path: group_path,
           default_username: Keyword.get(opts, :default_username, get_username_admin),
          ]
    case cmd(ctx, ["init", db_path]) do
      {stdout, 0} ->
        if String.contains?(stdout, "admin-user") do
          {:ok, _} = force_setting(ctx, "http_authentication_ok", "1")
          {:ok, _} = force_setting(ctx, "remote_user_ok", "1")

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

  @spec set_username(context(), String.t) :: context()
  def set_username(ctx, username) do
    Keyword.put(ctx, :default_username, username)
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
  def request_http(ctx, credentials, fossil_baseurl, method, url, body, content_type) do
    baseurl = Application.get_env(:efossils, :fossil_base_url)
    db_path = Keyword.get(ctx, :db_path)
    opts = case credentials do
             nil -> []
             credentials ->
               [hackney: [basic_auth: credentials]]
           end
    #fossil_url = get_fossil_url_from_pool(ctx, baseurl)
    fossil_url = Efossils.Http.ephimeral(ctx, "#{baseurl}/#{fossil_baseurl}")
    remote_url = fossil_url <> url
    method = case method do
               "GET" -> :get
               "POST" -> :post
               "PUT" -> :put
               "DELETE" -> :delete
             end
    # HACK: reemplaza usuario por el logeado
    username = Keyword.get(ctx, :default_username)

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
  def timeline(ctx, checkin, limit \\ 0) when is_binary(checkin) do
    db_path = Keyword.get(ctx, :db_path)
    case cmd(ctx, ["timeline", "-R", db_path, "-W", "0", "-n", Integer.to_string(limit), checkin]) do
      {stdout, 0} ->
        {:ok, {checkin, String.split(stdout, "\n", trim: true) |> tl}}
      {stdout, _} ->
        {:error, stdout}
    end
  end
  def timeline(ctx, date, limit) do
    timeline(ctx, Date.to_string(date), limit)
  end

  def last_day_timeline(ctx, limit \\ 0) do
    db_path = Keyword.get(ctx, :db_path)
    case cmd(ctx, ["timeline", "-R", db_path, "-W", "0", "-n", Integer.to_string(limit)]) do
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

  defp blob_uncompress(ctx, nil) do
    blob_uncompress(ctx, "")
  end
  defp blob_uncompress(ctx, indata) when is_binary(indata) do
    tmp_dir = System.tmp_dir!
    infile = Path.join(tmp_dir, "compress")
    outfile = Path.join(tmp_dir, "uncompress")
    File.write!(infile, indata)
    case cmd(ctx, ["test-uncompress", infile, outfile]) do
      {_, 0} ->
        outdata = File.read!(outfile)
        File.rm!(infile)
        File.rm!(outfile)
        {:ok, outdata}
      {stdout, _} ->
        {:error, stdout}
    end
  end
  defp blob_uncompress(ctx, _), do: blob_uncompress(ctx, "")
  
  defp blob_compress(ctx, indata) do
    tmp_dir = System.tmp_dir!
    infile = Path.join(tmp_dir, "uncompress")
    outfile = Path.join(tmp_dir, "compress")
    File.write!(infile, indata)
    case cmd(ctx, ["test-compress", infile, outfile]) do
      {_, 0} ->
        outdata = File.read!(outfile)
        File.rm!(infile)
        File.rm!(outfile)
        {:ok, outdata}
      {stdout, _} ->
        {:error, stdout}
    end
  end

  defp cmd(ctx, args, opts \\ []) do
    username = Keyword.get(opts, :username, Keyword.get(ctx, :default_username))
    env = [{"HOME", Keyword.get(ctx, :work_path)},
           {"FOSSIL_USER", username},
           {"REMOTE_USER", username}]
    System.cmd("fossil", args, [stderr_to_stdout: true, env: env] ++ opts)
  end

  defp get_repositories_path do
    path = Path.absname(Application.get_env(:efossils, :fossil_repositories_path))
     if File.exists?(path) do
       path
    else
      Application.app_dir(:efossils, path)
    end
  end

  defp get_work_path do
    path = Path.absname(Application.get_env(:efossils, :fossil_work_path))
    if File.exists?(path) do
      path
    else
      Application.app_dir(:efossils, path)
    end
  end

  defp get_username_admin do
    Application.get_env(:efossils, :fossil_user_admin)
  end
  
  def get_command do
    Application.get_env(:efossils, :fossil_bin)
  end
end
