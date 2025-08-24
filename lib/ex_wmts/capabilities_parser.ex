defmodule ExWMTS.CapabilitiesParser do
  @moduledoc """
  Parses WMTS GetCapabilities XML responses into structured Elixir data.
  """

  import ExWMTS.XPathHelpers
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
          identifier: text("Identifier"),
          title: text("Title"),
          abstract: text("Abstract"),
          keywords: ~x"./*[local-name()='Keywords']/*[local-name()='Keyword']/text()"sl,
          wgs84_bounding_box: element("WGS84BoundingBox"),
          bounding_box: element_list("BoundingBox"),
          metadata: element_list("Metadata"),
          dimensions: element_list("Dimension"),
          resource_urls: element_list("ResourceURL"),
          tile_matrix_set_links: element_list("TileMatrixSetLink"),
          formats: text_list("Format"),
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
