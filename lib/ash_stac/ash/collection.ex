defmodule AshStac.Ash.Collection do
  @moduledoc """
  Ash facade for STAC Collections.

  This resource has no database data layer. Actions delegate to pgSTAC through
  `AshStac.Pgstac`.
  """

  use Ash.Resource,
    domain: AshStac.Ash.Domain

  attributes do
    attribute :id, :string do
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
      argument(:id, :string, allow_nil?: false)
      manual(AshStac.Ash.Manual.GetCollection)
    end

    create :upsert do
      argument(:conn, :term, allow_nil?: false)
      argument(:document, :map, allow_nil?: false)
      manual(AshStac.Ash.Manual.UpsertCollection)
    end
  end
end
