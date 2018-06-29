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

  match "/user/:user/repository/:repository/xfer/*rest" do
    {conn, Coherence.Authentication.Utils.get_first_req_header(conn,  "authorization")}
    |> proxify_get_credentials
    |> proxify_basic_auth(rest)
  end

  match "/user/:user/repository/:repository/*rest" do
    opts = Coherence.Authentication.Session.init([])
    conn
    |> Coherence.Authentication.Session.call(opts)
    |> proxify(rest)
  end

  defp proxify_get_credentials({conn, <<"Basic ", creds64::binary >>}) do
    {:ok, creds} = Base.decode64(creds64)
    case String.split(creds, ":", parts: 2) do
      [email, password]  ->
        {conn, {email, password}}
      _ ->
        {conn, nil}
    end
  end
  defp proxify_get_credentials({conn, nil}), do: {conn, nil}

  defp proxify_basic_auth({conn, nil}, rest) do
    conn
    |> put_resp_header("WWW-Authenticate", ~s{Basic realm="efossils"})
    |> send_resp(401, "Unauthorized")
    |> halt
  end
  
  defp proxify_basic_auth({conn, {email, password}}, rest) do
    case Efossils.Repo.get_by(Efossils.Coherence.User, email: email) do
      nil ->
        conn
        |> send_resp(403, "Forbidden")
        |> halt
      user ->
        if Efossils.Coherence.User.checkpw(password, user.password_hash) do
          conn
          |> assign(:current_user, user)
          |> proxify(rest)
        else
          conn
          |> send_resp(403, "Forbidden")
          |> halt
        end
    end
  end
  
  defp proxify(conn, rest) do
    %{"repository" => repository_name, "user" => username} = conn.path_params
    repository = Efossils.Accounts.get_repository_by_name!(repository_name)
    username = repository.owner.lower_name
    {:ok, rctx} = Efossils.Accounts.context_repository(repository)
    credentials = case conn.assigns[:current_user] do
                    nil -> nil
                    current_user ->
                      {:ok, _rctx} = Efossils.Command.new_user(rctx,
                      current_user.email, current_user.id, current_user.email)
                      {current_user.email, current_user.email}
                  end
    # TODO: http://localhost:4000/fossil tomar de peticion
    # FIXME: esto puede es una posible amenaza de seguridad ya que este string se pasa
    #como argumento al commando *fossil*.
    fossil_base_url = EfossilsWeb.Utils.fossil_path("", repository.owner, repository) |> String.trim("/")
    baseurl = "http://#{conn.host}:#{conn.port}/#{fossil_base_url}"

    url = "/" <> Enum.join(rest,"/") <> "?" <> conn.query_string
    req_headers = Enum.into(conn.req_headers, %{})
    body = case req_headers["content-type"] do
             "application/x-fossil" ->
               Enum.into(stream_body(conn), "")
             _ ->
               {:multipart, Map.to_list(conn.body_params)}
           end
    case Efossils.Command.request_http(rctx, credentials, baseurl,
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
        IO.puts inspect error
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
