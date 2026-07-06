defmodule AshStac.Ash.Manual do
  @moduledoc false

  alias AshStac.{Collection, Item}

  @spec collection_record(Collection.t()) :: AshStac.Ash.Collection.t()
  def collection_record(%Collection{} = collection) do
    %AshStac.Ash.Collection{
      id: collection.id,
      document: Collection.to_map(collection)
    }
  end

  @spec item_record(Item.t()) :: AshStac.Ash.Item.t()
  def item_record(%Item{} = item) do
    %AshStac.Ash.Item{
      id: item.id,
      collection: item.collection,
      document: Item.to_map(item)
    }
  end
end

defmodule AshStac.Ash.Manual.GetCollection do
  @moduledoc false

  use Ash.Resource.ManualRead

  alias AshStac.Ash.Manual
  alias AshStac.Pgstac

  @impl true
  def read(query, _data_layer_query, _opts, _context) do
    conn = Ash.Query.get_argument(query, :conn)
    id = Ash.Query.get_argument(query, :id)

    case Pgstac.get_collection(conn, id) do
      {:ok, nil} -> {:ok, []}
      {:ok, collection} -> {:ok, [Manual.collection_record(collection)]}
      {:error, reason} -> {:error, reason}
    end
  end
end

defmodule AshStac.Ash.Manual.UpsertCollection do
  @moduledoc false

  use Ash.Resource.ManualCreate

  alias AshStac.Ash.Manual
  alias AshStac.Pgstac

  @impl true
  def create(changeset, _opts, _context) do
    conn = Ash.Changeset.get_argument(changeset, :conn)
    document = Ash.Changeset.get_argument(changeset, :document)

    with {:ok, collection} <- Pgstac.upsert_collection(conn, document) do
      {:ok, Manual.collection_record(collection)}
    end
  end
end

defmodule AshStac.Ash.Manual.GetItem do
  @moduledoc false

  use Ash.Resource.ManualRead

  alias AshStac.Ash.Manual
  alias AshStac.Pgstac

  @impl true
  def read(query, _data_layer_query, _opts, _context) do
    conn = Ash.Query.get_argument(query, :conn)
    collection = Ash.Query.get_argument(query, :collection)
    id = Ash.Query.get_argument(query, :id)

    case Pgstac.get_item(conn, collection, id) do
      {:ok, nil} -> {:ok, []}
      {:ok, item} -> {:ok, [Manual.item_record(item)]}
      {:error, reason} -> {:error, reason}
    end
  end
end

defmodule AshStac.Ash.Manual.SearchItems do
  @moduledoc false

  use Ash.Resource.ManualRead

  alias AshStac.Ash.Manual
  alias AshStac.Pgstac

  @impl true
  def read(query, _data_layer_query, _opts, _context) do
    conn = Ash.Query.get_argument(query, :conn)
    search_query = Ash.Query.get_argument(query, :query)

    with {:ok, items} <- Pgstac.search_items(conn, search_query) do
      {:ok, Enum.map(items, &Manual.item_record/1)}
    end
  end
end

defmodule AshStac.Ash.Manual.UpsertItem do
  @moduledoc false

  use Ash.Resource.ManualCreate

  alias AshStac.Ash.Manual
  alias AshStac.Pgstac

  @impl true
  def create(changeset, _opts, _context) do
    conn = Ash.Changeset.get_argument(changeset, :conn)
    document = Ash.Changeset.get_argument(changeset, :document)

    with {:ok, item} <- Pgstac.upsert_item(conn, document) do
      {:ok, Manual.item_record(item)}
    end
  end
end
