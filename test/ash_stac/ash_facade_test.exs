defmodule AshStac.AshFacadeTest do
  use ExUnit.Case, async: true

  defmodule FakeConn do
    def query("SELECT content FROM pgstac.collections WHERE id = $1", ["sentinel-2"]) do
      {:ok,
       %{
         rows: [
           [
             %{
               "stac_version" => "1.1.0",
               "id" => "sentinel-2",
               "description" => "Sentinel-2 scenes",
               "license" => "proprietary",
               "extent" => %{
                 "spatial" => %{"bbox" => [[-180, -90, 180, 90]]},
                 "temporal" => %{"interval" => [["2020-01-01T00:00:00Z", nil]]}
               },
               "links" => [
                 %{"rel" => "self", "href" => "https://example.test/collections/sentinel-2"}
               ]
             }
           ]
         ]
       }}
    end
  end

  test "reads collections through the Ash resource facade" do
    query =
      Ash.Query.for_read(AshStac.Ash.Collection, :get, %{
        conn: FakeConn,
        id: "sentinel-2"
      })

    assert {:ok, [record]} = Ash.read(query, domain: AshStac.Ash.Domain)
    assert record.id == "sentinel-2"
    assert record.document["stac_version"] == "1.1.0"
  end
end
