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

defmodule EfossilsWeb.Proxy.Plug do
  @moduledoc false

  import Plug.Conn
  
  def init(opts), do: opts
  def call(conn, opts) do
    conn
    |> EfossilsWeb.Proxy.Router.call(opts)
  end
end
#https://github.com/phoenixframework/phoenix/issues/459
defmodule EfossilsWeb.Proxy.Router do
  use Plug.Router
  require Logger
  
  plug :match
  plug :dispatch

  match "/user/:user/repository/:repository/download*rest" do
    conn
    |> send_resp(403, "Forbidden")
    |> halt
  end

  match "/user/:user/repository/:repository/tarball*rest" do
    conn
    |> send_resp(403, "Forbidden")
    |> halt
  end

  match "/user/:user/repository/:repository/zip*rest" do
    conn
    |> send_resp(403, "Forbidden")
    |> halt
  end

  match "/user/:user/repository/:repository/sqlar*rest" do
    conn
    |> send_resp(403, "Forbidden")
    |> halt
  end

  match "/user/:user/repository/:repository/*rest" do
    conn
    |> select_authentication(rest)
    |> authorization()
    |> proxify(rest)
  end

  defp select_authentication(conn, rest) do
    if String.ends_with?(Path.join(rest), "xfer") do
      conn
      |> put_repository()
      |> put_user_from_basic_auth()
    else
      conn = conn
      |> put_user_from_session
      |> put_repository()
      
      conn
      |> assign(:authenticated_user, conn.assigns[:current_user])
    end
  end
  
  defp put_repository(conn) do
    %{"repository" => repository_name} = conn.path_params
    repository =  Efossils.Accounts.get_repository_by_name!(repository_name)
    assign(conn, :current_repository, repository)
  end

  defp put_user_from_session(conn) do
    opts = Pow.Plug.Session.init([])
    conn |> Pow.Plug.Session.call(opts)
  end

  defp first_get_req_header(conn, key) do
    case get_req_header(conn, key) do
      [val | _rest] ->
        val
      [] ->
        nil
    end
  end

  defp put_user_from_basic_auth(conn) do
    credentials = first_get_req_header(conn, "authorization")
    case get_credentials_basic_auth(credentials) do
      {email, password} ->
        user = case Efossils.Repo.get_by(Efossils.User, email: email) do
                 nil -> 
                   Efossils.Repo.get_by(Efossils.User, nickname: email)
                 user ->
                   user
               end
        case user do
          nil -> conn
          user ->
            if Comeonin.Bcrypt.checkpw(password, user.password_hash) do
              assign(conn, :authenticated_user, user)
            else
              conn
            end
            |> assign(:current_user, user)
        end
      _ ->
        conn
    end
  end
  
  defp get_credentials_basic_auth(<<"Basic ", creds64::binary >>)  do
    {:ok, creds} = Base.decode64(creds64)
    case String.split(creds, ":", parts: 2) do
      [email, password]  ->
        {email, password}
      _ ->
        nil
    end
  end
  defp get_credentials_basic_auth(_), do: nil


  defp authorization(conn) do
    user = conn.assigns[:current_user]
    authenticated_user = conn.assigns[:authenticated_user]
    repository = conn.assigns[:current_repository]

    if repository.is_private == false do
      conn
    else
      cond do
        user == nil ->
          conn
          |> put_resp_header("WWW-Authenticate", ~s{Basic realm="efossils"})
          |> send_resp(401, "Unauthorized")
          |> halt
        authenticated_user == nil ->
          conn
          |> send_resp(403, "Forbidden")
          |> halt
        true ->
          conn
      end
    end
  end

  defp proxify(%Plug.Conn{state: :sent} = conn, _) do
    conn
  end
  defp proxify(conn, rest) do
    repository = conn.assigns[:current_repository]
    current_user = conn.assigns[:current_user]

    {:ok, rctx} = Efossils.Accounts.context_repository(repository)
    {credentials, anonymous} = cond do
      current_user == nil -> {nil, false}
      current_user.id == repository.owner_id ->
        {{current_user.nickname, current_user.email}, false}
      Efossils.Accounts.is_user_collaborator_for_repository(current_user, repository) ->
        {{current_user.nickname, current_user.email}, false}
      current_user.id != repository.owner_id ->
        #si usuario esta logeado en plataforma y no es colaborador
        #se le dan los permisos de usuario anonimo
        caps_anonymous = "hmnc"
        case Efossils.Command.capabilities_user(rctx, current_user.nickname, caps_anonymous) do
          {:error, :user_not_exists} ->
            {:ok, rctx} = Efossils.Command.new_user(rctx, current_user.nickname, current_user.id, current_user.email)
            {:ok, rctx} = Efossils.Command.capabilities_user(rctx, current_user.nickname, caps_anonymous)
            {{current_user.nickname, current_user.email}, true}
          {:ok, rctx} ->
            {{current_user.nickname, current_user.email}, true}
        end
      true ->
        nil
    end
    
    # TODO: http://localhost:4000/fossil tomar de peticion
    # FIXME: esto puede es una posible amenaza de seguridad ya que este string se pasa
    #como argumento al commando *fossil*.
    fossil_base_url = EfossilsWeb.Utils.fossil_path("", repository.owner, repository) |> String.trim("/")

    url = "/" <> Enum.join(rest, "/") <> "?" <> conn.query_string
    req_headers = Enum.into(conn.req_headers, %{})
    body = case req_headers["content-type"] do
             "application/x-fossil" ->
               Enum.into(stream_body(conn), <<>>)
             _ ->
               URI.encode_query(conn.body_params)
           end

    rctx = case credentials do
             nil ->
               if anonymous do
                 Efossils.Command.set_username(rctx, current_user.nickname)
               else
                 Efossils.Command.set_username(rctx, "nobody")
               end
             {username, _} ->
               Efossils.Command.set_username(rctx, username)
           end

    case Efossils.Command.request_http(rctx, credentials, fossil_base_url,
          conn.method, url, body, req_headers) do
      {:ok, {body, headers, status_code}} ->
        Enum.reduce(headers, conn, fn {key, val}, conn ->
          put_resp_header(conn, String.downcase(key), val)
        end)
        |> send_resp(status_code, body)
      %HTTPotion.Response{:body => body, :headers => headers, :status_code => status_code} ->
        Enum.reduce(headers.hdrs, conn, fn {key, val}, conn ->
          put_resp_header(conn, String.downcase(key), val)
        end)
        |> send_resp(status_code, body)
      %HTTPotion.ErrorResponse{message: message} ->
        conn
        |> put_status(:bad_gateway)
        |> send_resp(503, message)
    end
  end

  
  defp stream_body(conn) do
    Stream.resource(fn -> {:open, conn} end,
      fn {:open, conn} ->
        case  Plug.Conn.read_body(conn) do
          {:ok, data, conn} ->
            {[data], {:close, conn}}
          {:more, data, conn} ->
            {[data], {:cont, conn}}
        end
        {:cont, conn} ->
          case Plug.Conn.read_body(conn) do
            {:ok, data, conn} ->
              {[data], {:close, conn}}
            {:more, data, conn} ->
                {[data], {:cont, conn}}
          end
        {:close, conn} ->
          {:halt, conn}
      end,
      fn req -> req end)
  end
  

end

#TODO: se omite el parseo para dejar el `body` intacto
#y poder ser manipulado desde el router. Se supone
#que desde Plug.Routers.pass deberia pero
#el parser Plug.Routers.URLENCODED por defecto lo parsea
defmodule EfossilsWeb.Proxy.Parser do
  @behaviour Plug.Parsers

  def init(opts) do
     Keyword.pop(opts, :body_reader, {Plug.Conn, :read_body, []})
  end

  def parse(conn, "application", "x-fossil", _headers, {{mod, fun, args}, opts}) do
    {:ok, %{}, conn}
  end
  
  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end
end
