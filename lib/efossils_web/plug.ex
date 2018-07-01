defmodule EfossilsWeb.Proxy.Plug do
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

  match "/user/:user/repository/:repository/xfer/*rest" do
    conn
    |> put_repository()
    |> put_user_from_basic_auth()
    |> authorization()
    |> proxify(rest)
  end

  match "/user/:user/repository/:repository/*rest" do
    opts = Coherence.Authentication.Session.init([])
    conn
    |> Coherence.Authentication.Session.call(opts)
    |> put_repository()
    |> proxify(rest)
  end

  defp put_repository(conn) do
    %{"repository" => repository_name} = conn.path_params
    repository =  Efossils.Accounts.get_repository_by_name!(repository_name)
    assign(conn, :current_repository, repository)
  end

  defp put_user_from_basic_auth(conn) do
    case get_credentials_basic_auth(Coherence.Authentication.Utils.get_first_req_header(conn,  "authorization")) do
      {email, password} ->
        case Efossils.Repo.get_by(Efossils.Coherence.User, email: email) do
          nil -> conn
          user ->
            if Efossils.Coherence.User.checkpw(password, user.password_hash) do
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

    {:ok, rctx} = Efossils.Accounts.context_repository(repository)
    credentials = case conn.assigns[:current_user] do
                    nil -> nil
                    current_user ->
                      {current_user.lower_name, current_user.email}
                  end

    # TODO: http://localhost:4000/fossil tomar de peticion
    # FIXME: esto puede es una posible amenaza de seguridad ya que este string se pasa
    #como argumento al commando *fossil*.
    fossil_base_url = EfossilsWeb.Utils.fossil_path("", repository.owner, repository) |> String.trim("/")

    url = "/" <> Enum.join(rest,"/") <> "?" <> conn.query_string
    req_headers = Enum.into(conn.req_headers, %{})
    body = case req_headers["content-type"] do
             "application/x-fossil" ->
               Enum.into(stream_body(conn), "")
             _ ->
               {:multipart, Map.to_list(conn.body_params)}
           end

    rctx = case credentials do
             nil -> rctx
             {username, _} ->
               Efossils.Command.set_username(rctx, username)
           end

    case Efossils.Command.request_http(rctx, credentials, fossil_base_url,
          conn.method, url, body, req_headers["content-type"]) do
      {:ok, response} ->
        headers = Enum.into(response.headers, %{})
        case response.status_code do
          302 ->
            conn
            |> put_resp_content_type(headers["Content-Type"])
            |> put_resp_header("Location", headers["Location"])
          _ ->
            conn
            |> put_resp_content_type(headers["Content-Type"])
        end
        |> send_resp(response.status_code, response.body)
      {:error, error} ->
        conn
        |> put_status(:bad_gateway)
        |> send_resp(503, inspect error)
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
              {:halt, conn}
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
