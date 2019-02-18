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

defmodule EfossilsWeb.Utils do
  @moduledoc false
  alias Efossils.User
  alias Efossils.Accounts.Collaboration
  alias Efossils.ActivityPub
  alias Efossils.ActivityStreams

  defdelegate fossil_path(rest, user, repo), to: Efossils.Utils

  def public_id(%User{nickname: nickname}) do
    "#{base_url()}/users/#{nickname}"
  end
  
  def public_id(%Collaboration{user: user}) do
    "#{base_url()}/users/#{user.nickname}"
  end

  def public_id(:instance) do
    "#{base_url()}/instance"
  end

  def inbox_url(:instance) do
    "#{base_url()}/inbox"
  end

  def base_url do
    EfossilsWeb.Endpoint.url()
  end

  def host do
    uri = URI.parse(base_url)
    "#{uri.host}:#{uri.port}"
  end

  defp request_headers(url) do
    uri = URI.parse(url)

    date = Timex.now |> Timex.format!("{RFC1123}")
    signature = [{"(request-target)", "post #{uri.path}"},
                  {"host", host()},
                  {"date", date}]
                  |> Enum.map_join("\n", fn {k,v} -> "#{k}: #{v}" end)
                  |> Efossils.Utils.sign_and_encode

    %{"Signature" => "keyId=\"#{public_id(:instance)}\",headers=\"(request-target) host date\",signature=\"#{signature}\"",
      "Date" => date,
      "Content-Type" => "application/json"}
  end

  def get(url) do
    headers = request_headers(url)
    decoder = Phoenix.json_library
    case HTTPotion.get(url, [headers: headers]) do
      %HTTPotion.Response{body: body, status_code: 200} ->
        decoder.decode(body)
      %HTTPotion.ErrorResponse{message: message} ->
        {:error, message}
      %HTTPotion.Response{body: body, status_code: status_code} ->
        {:error, status_code}
    end
  end

  def post(url, content) when is_map(content) do
    headers = request_headers(url)
    {:ok, body} = Phoenix.json_library.encode(Map.put(content, "@context", "https://www.w3.org/ns/activitystreams"))
    case HTTPotion.post(url, [body: body, headers: headers]) do
      %HTTPotion.Response{body: body, status_code: 200} ->
        {:ok, body}
      %HTTPotion.ErrorResponse{message: message} ->
        {:error, message}
      %HTTPotion.Response{body: body, status_code: status_code} ->
        {:error, status_code}
    end
  end

  def post_activiy(url, content) when is_map(content) do
    headers = request_headers(url)
    |> Map.put("Content-Type", "application/activity+json")

    {:ok, body} = Phoenix.json_library.encode(Map.put(content, "@context", "https://www.w3.org/ns/activitystreams"))
    case HTTPotion.post(url, [body: body, headers: headers]) do
      %HTTPotion.Response{body: body, status_code: 200} ->
        {:ok, body}
      %HTTPotion.ErrorResponse{message: message} ->
        {:error, message}
      %HTTPotion.Response{body: body, status_code: status_code} ->
        {:error, status_code}
    end
  end

  def actor_self do
    %Efossils.ActivityPub.Vocabulary.Actor{
      type: "Application",
      id: EfossilsWeb.Utils.public_id(:instance),
      name: Efossils.Utils.federated_name(),
      inbox: EfossilsWeb.Utils.inbox_url(:instance)
    }
  end

  def object_self do
    %ActivityStreams.Vocabulary.Object{
      type: "Application",
      id: EfossilsWeb.Utils.public_id(:instance),
      name: Efossils.Utils.federated_name(),
    }
  end

  def ap_follow(ap_id) do
    object = ActivityPub.Vocabulary.Actor.cast(ap_id)
    inbox_url = ActivityPub.Vocabulary.Actor.first_inbox(object)
    document = %ActivityStreams.Vocabulary.Follow{
      actor: actor_self,
      object: object
    }
    |> ActivityStreams.render
    post_activiy(inbox_url, document)
  end
end
