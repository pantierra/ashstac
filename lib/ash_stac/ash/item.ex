defmodule AshStac.Ash.Item do
  @moduledoc """
  Ash facade for STAC Items.
  """

  use Ash.Resource,
    domain: AshStac.Ash.Domain

  attributes do
    attribute :id, :string do
      allow_nil?(false)
      primary_key?(true)
      public?(true)
    end

    attribute :collection, :string do
      allow_nil?(false)
      primary_key?(true)
      public?(true)
    end

    attribute :document, :map do
      allow_nil?(false)
      public?(true)
    end
  end

  actions do
    read :get do
      argument(:conn, :term, allow_nil?: false)
      argument(:collection, :string, allow_nil?: false)
      argument(:id, :string, allow_nil?: false)
      manual(AshStac.Ash.Manual.GetItem)
    end

    read :search do
      argument(:conn, :term, allow_nil?: false)
      argument(:query, :map, allow_nil?: false)
      manual(AshStac.Ash.Manual.SearchItems)
    end

    create :upsert do
      argument(:conn, :term, allow_nil?: false)
      argument(:document, :map, allow_nil?: false)
      manual(AshStac.Ash.Manual.UpsertItem)
    end
  end
end
