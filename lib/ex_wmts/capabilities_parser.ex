defmodule ExWMTS.CapabilitiesParser do
  @moduledoc """
  Parses WMTS GetCapabilities XML responses into structured Elixir data.
  """

  import SweetXml

  alias ExWMTS.Layer
  alias ExWMTS.Model.Common
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
      layers:
        parsed_xml
        |> xpath(~x"//*[local-name()='Layer']"l,
          identifier: ~x"./*[local-name()='Identifier']/text()"s,
          title: ~x"./*[local-name()='Title']/text()"s,
          abstract: ~x"./*[local-name()='Abstract']/text()"s,
          formats: ~x"./*[local-name()='Format']/text()"ls,
          tile_matrix_sets: ~x"./*[local-name()='TileMatrixSetLink']/*[local-name()='TileMatrixSet']/text()"ls,
          styles: ~x"./*[local-name()='Style']/*[local-name()='Identifier']/text()"ls
        )
        |> make_layers(),
      tile_matrix_sets:
        parsed_xml
        |> xpath(~x"//*[local-name()='TileMatrixSet']"l,
          identifier: ~x"./*[local-name()='Identifier']/text()"s,
          supported_crs: ~x"./*[local-name()='SupportedCRS']/text()"s,
          matrices: ~x"./*[local-name()='TileMatrix']"l
        )
        |> make_tile_matrix_sets(),
      formats:
        parsed_xml
        |> xpath(~x"//*[local-name()='Format']/text()"ls)
        |> Enum.map(&Common.normalize_text/1)
        |> Enum.reject(&(&1 == nil))
        |> Enum.uniq()
    }

    {:ok, capabilities}
  end

  defp make_layers(layers) do
    layers
    |> Enum.map(&Layer.build/1)
    |> Enum.reject(&(&1 == nil))
  end

  defp make_tile_matrix_sets(tms) do
    tms
    |> Enum.map(&TileMatrixSet.build/1)
    |> Enum.reject(&(&1 == nil))
  end
end
