defmodule ExWMTS.CapabilitiesParser do
  @moduledoc """
  Parses WMTS GetCapabilities XML responses into structured Elixir data.
  """

  import SweetXml

  alias ExWMTS.Model.Common
  alias ExWMTS.ServiceIdentification

  @type layer :: %{
          identifier: String.t(),
          title: String.t(),
          abstract: String.t() | nil,
          formats: [String.t()],
          tile_matrix_sets: [String.t()],
          styles: [String.t()]
        }

  @type tile_matrix_set :: %{
          identifier: String.t(),
          supported_crs: String.t(),
          matrices: [tile_matrix()]
        }

  @type tile_matrix :: %{
          identifier: String.t(),
          scale_denominator: float(),
          top_left_corner: {float(), float()},
          tile_width: integer(),
          tile_height: integer(),
          matrix_width: integer(),
          matrix_height: integer()
        }

  @type capabilities :: %{
          service_identification: %{
            title: String.t(),
            abstract: String.t() | nil,
            service_type: String.t(),
            service_type_version: String.t()
          },
          layers: [layer()],
          tile_matrix_sets: [tile_matrix_set()],
          formats: [String.t()]
        }

  @doc """
  Parses GetCapabilities XML response into structured data.
  """
  @spec parse(String.t()) :: {:ok, capabilities()} | {:error, term()}
  def parse(xml) when is_binary(xml) do
    parsed_xml = SweetXml.parse(xml)

    capabilities = %{
      service_identification:
        parsed_xml
        |> xpath(~x"//*[local-name()='ServiceIdentification']")
        |> ServiceIdentification.build(),
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
    |> Enum.map(&ExWMTS.Layer.build/1)
    |> Enum.reject(&(&1 == nil))
  end

  defp make_tile_matrix_sets(tms) do
    tms
    |> Enum.map(&ExWMTS.TileMatrixSet.build/1)
    |> Enum.reject(&(&1 == nil))
  end
end
