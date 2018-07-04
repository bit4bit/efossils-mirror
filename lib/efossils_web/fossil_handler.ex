defmodule EfossilsWeb.FossilHandler do
  @moduledoc """
  Implementa `cowboy_http_handler` para realizar tunel al comando *fossil http*.
  TODO : implementar carga de usuario de session activa.
  """

  
  def init({:tcp, :http}, req, opts) do
    baseurl = Application.get_env(:efossils, :fossil_base_url)
    {query_string, req} = :cowboy_req.qs(req)
    {method, req} = :cowboy_req.method(req)
    {username, req} = :cowboy_req.binding(:user, req)
    {repository_name, req} = :cowboy_req.binding(:repository, req)
    {headers, req} = :cowboy_req.headers(req)
    {path_info, req} = :cowboy_req.path_info(req)
    credentials = case :cowboy_req.parse_header("authorization", req) do
      {:ok, {"basic", {username, password}}, req} ->
                      case Efossils.Repo.get_by(Efossils.Coherence.User, email: username) do
                        nil -> nil
                        user ->
                          if Efossils.Coherence.User.checkpw(password, user.password_hash) do
                            {user.lower_name, user.email}
                          else
                            nil
                          end
                      end
                    _rest ->
                      nil
        end

      
    mheaders = Enum.into(headers, %{})
    repository =  Efossils.Accounts.get_repository_by_name!(repository_name)
    {:ok, ctx} = Efossils.Accounts.context_repository(repository)
    fossil_base_url = EfossilsWeb.Utils.fossil_path("", repository.owner, repository) |> String.trim("/")
    url = "/" <> Path.join(path_info)
    proc = http(ctx, "#{baseurl}/#{fossil_base_url}")
    Process.send_after(self(), {:request, proc, method, url, headers, credentials}, 1)
    {:loop, req, %{repository: repository,
                   proc: proc, state: :header,
                   headers: [],
                   type: :http_bin,
                   more: "",
                   more_len: 0}}
  end

  defp send_body(req, proc) do
    case :cowboy_req.body(req, [length: :infinity] ) do
      {:ok, data, _req} ->
        Porcelain.Process.send_input(proc, data)
      {:more, data, req} ->
        Porcelain.Process.send_input(proc, data)
        send_body(req, proc)
    end
  end

  defp http(ctx, baseurl) do
    pid = self()
    db_path = Keyword.get(ctx, :db_path)
    username =  Keyword.get(ctx, :default_username)
    env = [{"HOME", Keyword.get(ctx, :work_path)},
           {"FOSSIL_USER", username},
           {"REMOTE_USER", username}]
    %Porcelain.Process{:err => nil} = Porcelain.spawn(Efossils.Command.get_command, ["http", "--nossl", "--baseurl", baseurl, db_path], [in: :receive, out: {:send, pid}, env: env])
  end

  def parse_packet(data, req, %{type: type} = state) when is_binary(data) do
    parse_packet(:erlang.decode_packet(type, data, [packet_size: 0]), req, state)
  end
  def parse_packet({:ok, packet, rest}, req, state) do
    case put_header(packet, req, state) do
      {:more, req, state} ->
        parse_packet(rest, req, state)
      {:done, req, state} ->
        {:done, rest, req, state}
      resp ->
        resp
    end
  end
  
  def parse_packet(rest, req, state) do
    {rest, req, state}
  end

  def info({_pid, :data, :out, data}, req, %{more_len: more_len, state: :header} = state) when more_len == 0 do
    case parse_packet(data, req, state) do
      {{:more, :undefined}, req, state} ->
        {:loop, req, %{state | more_len: 100}}
      {{:more, len}, req, state} ->
        {:loop, req, %{state | more_len: len}}
      {:done, rest, req, state} ->
        :ok = :cowboy_req.chunk(rest, req)
        {:loop, req, %{state | state: :body}}
      {resp, req, state} ->
        resp
    end
  end
  
  def info({_pid, :data, :out, data}, req,
    %{state: :header, more_len: more_len, more: more} = state) when more_len > 0 do
    offset = more_len - String.length(data)
    if offset > 0 do
      {:loop, req, %{state | more_len: offset, more: more <> data}}
    else
      {head, tail} = String.split_at(data, more_len)
      case parse_packet(head, req, state) do
        {{:more, len}, req, state} ->
          {:loop, req, %{state | more_len: len, more: tail}}
        {:done, req, state} ->
          {:loop, req, %{state | state: :body, more_len: 0, more: ""}}
        {resp, req, state} ->
          resp
      end
    end
  end

  def info({_pid, :data, :out, data}, req, %{state: :body} = state) do
    case :cowboy_req.chunk(data, req) do
      :ok ->
        {:loop, req, state}
      {:error, :closed} ->
        {:ok, req, state}
    end
  end
     
  def info({_pid, :result, _proc}, req, state) do
    {:ok, req, state}
  end
  
  def info({:request, proc, method, url, headers, credentials},  req, state) do
    header = Enum.reduce(headers, "#{method} #{url} HTTP/1.0\r\n", fn {_key, nil}, header ->
      header
      {"authorization", val}, header ->
        case credentials do
          {username, password} ->
            basic = Base.encode64("#{username}:#{password}")
            header <> "authorization: Basic #{basic}\r\n"
          _ ->
            header <> "authorization: #{val}\r\n"
        end
      {key, val}, header ->
      header <> "#{key}: #{val}\r\n"
    end) <> "\r\n"
    Porcelain.Process.send_input(proc, header)
    send_body(req, proc)
    {:loop, req, state}
  end

  
  def put_header({:http_response, {majer, minor}, status_code, http_string} = res, req, state) do
    state = Map.put(state, :status_code, status_code)
    |> Map.put(:headers, [])
    |> Map.put(:type, :httph_bin)
    {:more, req, state}
  end

  def put_header({:http_header, _, http_field, _, http_value}, req, state) do
    {:more, req, %{state | headers: state.headers ++ [{http_field, http_value}]}}
  end

  def put_header(:http_eoh, req, %{status_code: status_code, headers: headers} = state) do
    sheaders = Enum.map(headers, fn {key, val} when is_binary(key) ->
      {key, val}
      {key, val} when is_atom(key) ->
        {Atom.to_string(key), val}
    end)
    {:ok, req} = :cowboy_req.chunked_reply(status_code, sheaders, req)

    {:done, req, state}
  end
  def put_header({:http_error, error}, req, state) do
    {:more, req, state}
  end  

  def terminate(:overflow, req, state) do
    raise "cowboy overflow reached, please verify loop_max_buffer"
    :ok
  end
  def terminate(_reason, req, %{proc: proc} = state) do
    Porcelain.Process.signal(proc, :kill)
    # `reason` 
    :ok
  end
end
