defmodule EfossilsWeb.ActivityPubController do
  use EfossilsWeb, :controller
  alias EfossilsWeb.ErrorView

  alias Efossils.Repo
  alias Efossils.ActivityPub
  alias Efossils.ActivityStreams.Vocabulary
  alias Efossils.Accounts

  def who(conn, _params) do
    case Efossils.Utils.raw_public_key() do
      {:ok, public_key} ->
        document = %{
        "@context"=> ["https://www.w3.org/ns/activitystreams",
                      "https://w3id.org/security/v1"],
        "id" => EfossilsWeb.Utils.public_id(:instance),
        "type" => "Application",
        "name" => Efossils.Utils.federated_name(),
        "preferredUsername" => Efossils.Utils.federated_name(),
        "inbox" => EfossilsWeb.Utils.inbox_url(:instance),
        
        "publicKey" => %{
          "id" => EfossilsWeb.Utils.public_id(:instance) <> "#main-key",
          "owner" => EfossilsWeb.Utils.public_id(:instance),
          "publicKeyPem" => public_key
        }
      }
        json(conn, document)
      _ ->
        conn
        |> put_resp_header("content-type", "application/activity+json")
        |> put_status(:not_found)
        |> put_view(ErrorView)
        |> render(:"404")
    end
  end

  def webfinger(conn, %{"resource" => resource}) do
    host = EfossilsWeb.Endpoint.host()
    regex = ~r/(acct:)?(?<username>\w+)@#{host}/
    instance_subject = "#{Efossils.Utils.federated_name}@#{host}"
    federated_name = Efossils.Utils.federated_name()
    case Regex.named_captures(regex, resource) do
      %{"username" => ^federated_name} ->
        document = %{
        "subject": instance_subject,
        "links": [
          %{
            "rel": "self",
            "type": "application/activity+json",
            "href": EfossilsWeb.Utils.public_id(:instance)
          }
        ]
      }
        json(conn, document)
      _ ->
        conn
        |> put_status(:not_found)
        |> put_view(ErrorView)
        |> render(:"404") 
    end
  end

  def send_inbox(conn, _params) do
    params = conn.body_params
    parse_inbox(conn, params)
  end

  defp parse_inbox(conn, %{"type" => "Create", "actor" => actor_id, "object" => object_id} = document) do
    actor = Vocabulary.cast(actor_id)
    object = Vocabulary.cast(object_id)
    process_create(conn, actor, object)
  end
  
  defp parse_inbox(conn, %{"type" => "Accept", "actor" => actor, "object" => object} = document) do
    process_accept(conn,
      Vocabulary.Actor.cast(actor),
      Vocabulary.Object.cast(object)
    )
  end
  
  defp parse_inbox(conn, %{"type" => "Follow", "actor" => actor, "object" => object} = document) do
    # TODO: buscar nombre retomo
    process_follow(conn,
      Vocabulary.Actor.cast(actor),
      Vocabulary.Object.cast(object))
  end

  defp process_create(conn, actor, %ActivityStreams.Document{} = object) do
  end
  
  defp process_accept(conn, actor, object) do
    json(conn, "ok")
  end
  
  defp process_follow(conn, actor, object) do
    case ActivityPub.get_follow_by_actor_id(actor.id) do
      nil ->
        case ActivityPub.create_follow(%{"actor": actor}) do
          {:ok, follow} ->
            accept = %Vocabulary.Accept{actor: EfossilsWeb.Utils.actor_self(),
                                        object: %Vocabulary.Follow{
                                          actor: actor,
                                          object: object
                                        }}

            ActivityPub.Notificator.send(accept)
            json(conn, "ok")
          {:error, error} ->
            json(conn, error)
        end
      _ ->
        json(conn, "ok")
    end
  end

end
