defmodule Efossils.ActivityPub.Vocabulary do
  alias Efossils.ActivityStreams

  def cast(%{"type" => "Actor"} = attrs) do
    ActivityStreams.Actor.cast(attrs)
  end
  def cast(%{"type" => "Document"} = attrs) do
    ActivityStreams.Document.cast(attrs)
  end

  defmodule Actor do
    @derive Jason.Encoder
    import ActivityStreams.Vocabulary.ObjectRetrieve

    defstruct Keyword.merge(ActivityStreams.Vocabulary.Actor.fields, [
          type: "Actor",
          inbox: "",
          outbox: ""
        ])

    def first_inbox(%Actor{inbox: url}) when is_binary(url) do
      url
    end
    def first_inbox(%{"inbox" => url}) when is_binary(url) do
      url
    end

    def cast(url) when is_binary(url) do
      cast(get!(url))
    end
    def cast(attrs \\ %{}) when is_map(attrs) do
      %Actor{}
      |> Efossils.Utils.cast(attrs, [:id,
                                    :name,
                                    :inbox,
                                    :outbox,
                                    :following,
                                    :followers])
    end
  end
end
