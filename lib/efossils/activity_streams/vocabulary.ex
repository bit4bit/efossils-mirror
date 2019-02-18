defmodule Efossils.ActivityStreams do
  def render(content) do
    content
    |> Map.merge(%{"@context": "https://www.w3.org/ns/activitystreams"})
  end
end

defmodule Efossils.ActivityStreams.Vocabulary do
  defmodule ObjectRetrieve do
    def get!(ap_id) do
      {:ok, document} = EfossilsWeb.Utils.get(ap_id)
      document
    end
  end

  
  defmodule OrderedCollection do
    defstruct type: "OrderedCollection",
      orderedItems: []

    def dedup_by_id(collection) do
      collection.orderedItems
      |> Enum.dedup_by(fn %{"id" => id} -> id
        %{id: id} -> id
        val -> val
      end)
    end
  end

  defimpl Enumerable, for: OrderedCollection do
    def reduce(collection, acc, fun) do
      Enum.reduce(collection.orderedItems, acc, fun)
    end

    def count(collection), do: {:ok, Enum.count(collection.orderedItems)}
  end

  defimpl Jason.Encoder, for: OrderedCollection do
    def encode(%OrderedCollection{} = collection, opts) do
      collection1 = Map.put(Map.from_struct(collection), :totalitems, Enum.count(collection))
      Jason.Encode.map(collection1, opts)
    end
  end


  #https://www.w3.org/TR/2018/REC-activitypub-20180123/#retrieving-objects
  defmodule Object do
    @derive Jason.Encoder
    import ObjectRetrieve
    @fields [
      type: "Object",
      name: "",
      id: nil
    ]
    def fields, do: @fields

    defstruct @fields

    def ap_id(object) when is_binary(object) do
      object
    end
    def ap_id(%Object{id: id}) do
      id
    end
    def ap_id(%{"id" => id}) do
      id
    end
    
    def cast(url) when is_binary(url) do
      cast(get!(url))
    end
    def cast(attrs \\ %{}) do
      %Object{}
      |> Efossils.Utils.cast(attrs, [:id, :name])
    end
  end

  defmodule Activity do
    @derive Jason.Encoder
    defstruct Object.fields |> Keyword.merge([
      type: "Activity",
      object: nil,
      actor: nil,
      target: nil,
      result: nil,
      origin: nil,
      instrument: nil
    ])
  end

  defmodule Document do
    @derive Jason.Encoder
    defstruct Object.fields |> Keyword.merge([
      type: "Document",
    ])

    def cast(attrs \\ %{}) do
      %Document{}
      |> Efossils.Utils.cast(attrs, Keyword.keys(Object.fields))
    end
  end

  defmodule Actor do
    @derive Jason.Encoder
    import ObjectRetrieve
    @fields [type: "Actor",
             name: "",
             id: nil,
             #https://www.w3.org/TR/2018/REC-activitypub-20180123/#actor-objects
             inbox: %OrderedCollection{},
             outbox: %OrderedCollection{},
             following: "",
             followers: "",
             liked: ""]
    def fields, do: @fields

    defstruct @fields
    
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
      |> Efossils.Utils.cast(attrs, [:id, :name, :inbox, :outbox, :following, :followers])
    end
  end



  defmodule Follow do
    @derive Jason.Encoder
    defstruct type: "Follow", actor: %Actor{}, object: %Object{}
  end
  
  defmodule Accept do
    @derive Jason.Encoder
    defstruct type: "Accept",
      actor: %Actor{},
      object: %Object{}
  end



  
end


