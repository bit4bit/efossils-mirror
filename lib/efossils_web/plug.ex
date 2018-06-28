defmodule EfossilsWeb.Proxy.Plug do
  import Plug.Conn
  
  def init(opts), do: opts
  def call(conn, opts) do
    conn
    |> EfossilsWeb.Proxy.Router.call(opts)
  end
end

defmodule EfossilsWeb.Proxy.Router do
  use Plug.Router
  require Logger

  plug Plug.Parsers, parsers: [:urlencoded, :multipart]
  plug :match
  plug :dispatch
  
  match "/user/:user/repository/:repository/*rest" do
    {Plug.Adapters.Cowboy.Conn, payload} = conn.adapter
    %{"repository" => repository, "user" => username} = conn.path_params
    IO.puts inspect rest
    {:ok, rctx} = Efossils.Command.init_repository(repository, username)
    # TODO: http://localhost:4000/fossil tomar de peticion
    # FIXME: esto puede es una posible amenaza de seguridad ya que este string se pasa
    #como argumento al commando *fossil*.
    baseurl = "http://#{conn.host}:#{conn.port}/fossil/user/#{username}/repository/#{repository}"
    url = "/" <> Enum.join(rest,"/") <> "?" <> conn.query_string
    case Efossils.Command.request_http(rctx, baseurl, url) do
      {:ok, response} ->
        headers = Enum.into(response.headers, %{})
        conn
        |> put_resp_content_type(headers["Content-Type"])
        |> send_resp(response.status_code, response.body)
      {:error, error} ->
        conn
        |> put_status(:bad_gateway)
        |> send_resp(503, inspect error)
    end
  end
end
