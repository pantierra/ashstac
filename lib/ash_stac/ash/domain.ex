defmodule AshStac.Ash.Domain do
  @moduledoc """
  Optional Ash domain for STAC resources backed by `AshStac.Pgstac`.
  """

  use Ash.Domain

  resources do
    resource(AshStac.Ash.Collection)
    resource(AshStac.Ash.Item)
  end
end
