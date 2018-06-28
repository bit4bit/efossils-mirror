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
  
  match "/user/:user/repository/:repository" do
    {Plug.Adapters.Cowboy.Conn, payload} = conn.adapter
    %{"repository" => repository, "user" => username} = conn.path_params

    {:ok, rctx} = Efossils.Command.init_repository(repository, username)
    conn = Plug.Conn.put_resp_content_type(conn, "text/plain")
    conn = Plug.Conn.send_chunked(conn, 200)
  {proc, stream} = Stream.map(["GET /\r\n"], fn data ->
      data
    end)
    |> Stream.concat(stream_headers(conn))
      |> Stream.concat(Stream.map(["\r\n"],
        fn data ->
          data
        end))
        |> Stream.each(fn data ->
        Logger.debug(inspect data)
      end)
      |> Efossils.Command.stream_http(rctx)
        
      stream
      |> Stream.each(fn data ->
        Plug.Conn.chunk(conn, data)
      end)
      |> Stream.run

      Efossils.Command.stream_await(proc)
      conn
  end

  defp http_header(conn) do
    conn.method <> " " <> conn.request_path
  end
  
  defp stream_headers(conn) do
    Stream.map(conn.req_headers,
      fn ({key, val}) ->
        "#{key}: #{val}\r\n"
      end)
  end
  
  defp stream_body(conn) do
    Stream.resource(
      fn -> {:start, conn} end,
      fn {:done, conn} ->
        {:halt, conn}
        {_, conn} ->
          case Plug.Conn.read_body(conn, length: 10) do
            {:ok, data, conn} -> {[data], {:done, conn}}
            {:more, data, conn} -> {[data], {:cont, conn}}
            _ -> {:halt, conn}
          end
      end,
      fn(req) -> req  end)
  end
end
