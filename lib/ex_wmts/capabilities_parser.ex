defmodule ExWMTS.CapabilitiesParser do
  @moduledoc """
  Parses WMTS GetCapabilities XML responses into structured Elixir data.
  """

  import SweetXml

  alias ExWMTS.Layer
  alias ExWMTS.Model.Common
  alias ExWMTS.OperationsMetadata
  alias ExWMTS.ServiceIdentification
  alias ExWMTS.ServiceProvider
  alias ExWMTS.TileMatrixSet

  def parse(xml) when is_binary(xml) do
    parsed_xml = SweetXml.parse(xml)

    capabilities = %{
      service_identification:
        parsed_xml
        |> xpath(~x"//*[local-name()='ServiceIdentification']")
        |> ServiceIdentification.build(),
      service_provider:
        parsed_xml
        |> xpath(~x"//*[local-name()='ServiceProvider']")
        |> ServiceProvider.build(),
      operations_metadata:
        parsed_xml
        |> xpath(~x"//*[local-name()='OperationsMetadata']")
        |> OperationsMetadata.build(),
      layers:
        parsed_xml
        |> xpath(~x"//*[local-name()='Layer']"l,
          identifier: ~x"./*[local-name()='Identifier']/text()"s,
          title: ~x"./*[local-name()='Title']/text()"s,
          abstract: ~x"./*[local-name()='Abstract']/text()"s,
          keywords: ~x"./*[local-name()='Keywords']/*[local-name()='Keyword']/text()"sl,
          wgs84_bounding_box: ~x"./*[local-name()='WGS84BoundingBox']"o,
          bounding_box: ~x"./*[local-name()='BoundingBox']"l,
          metadata: ~x"./*[local-name()='Metadata']"l,
          dimensions: ~x"./*[local-name()='Dimension']"l,
          resource_urls: ~x"./*[local-name()='ResourceURL']"l,
          tile_matrix_set_links: ~x"./*[local-name()='TileMatrixSetLink']"l,
          formats: ~x"./*[local-name()='Format']/text()"ls,
          tile_matrix_sets: ~x"./*[local-name()='TileMatrixSetLink']/*[local-name()='TileMatrixSet']/text()"ls,
          styles: ~x"./*[local-name()='Style']/*[local-name()='Identifier']/text()"ls
        )
        |> Layer.build(),
      tile_matrix_sets:
        parsed_xml
        |> xpath(~x"//*[local-name()='TileMatrixSet']"l)
        |> TileMatrixSet.build(),
      formats:
        parsed_xml
        |> xpath(~x"//*[local-name()='Format']/text()"ls)
        |> Enum.map(&Common.normalize_text/1)
        |> Enum.reject(&(&1 == nil))
        |> Enum.uniq()
    }

    {:ok, capabilities}
  end
end
