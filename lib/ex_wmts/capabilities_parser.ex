defmodule ExWMTS.CapabilitiesParser do
  @moduledoc """
  Parses WMTS GetCapabilities XML responses into structured Elixir data.
  """

  import SweetXml

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
        |> make_service_identification(),
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
        |> make_global_formats()
    }

    {:ok, capabilities}
  end

  defp make_service_identification(nil),
    do: %{title: "Unknown Service", abstract: nil, service_type: "WMTS", service_type_version: "1.0.0"}

  defp make_service_identification(service_node),
    do: %{
      title: service_node |> xpath(~x"./*[local-name()='Title']/text()"s) |> normalize_text("Unknown Service"),
      abstract: service_node |> xpath(~x"./*[local-name()='Abstract']/text()"s) |> normalize_text(nil),
      service_type: service_node |> xpath(~x"./*[local-name()='ServiceType']/text()"s) |> normalize_text("WMTS"),
      service_type_version:
        service_node |> xpath(~x"./*[local-name()='ServiceTypeVersion']/text()"s) |> normalize_text("1.0.0")
    }

  defp make_layers(layers) do
    layers
    |> Enum.map(&make_layer/1)
    |> Enum.reject(fn layer -> layer == nil end)
  end

  defp make_layer(layer_data) do
    identifier = normalize_text(layer_data.identifier, nil)
    title = normalize_text(layer_data.title, identifier)
    abstract = normalize_text(layer_data.abstract, nil)

    formats =
      layer_data.formats
      |> Enum.map(&normalize_text/1)
      |> Enum.reject(fn fmt -> fmt == nil end)
      |> Enum.uniq()

    tile_matrix_sets =
      layer_data.tile_matrix_sets
      |> Enum.map(&normalize_text/1)
      |> Enum.reject(fn tms -> tms == nil end)

    styles =
      layer_data.styles
      |> Enum.map(&normalize_text/1)
      |> Enum.reject(fn style -> style == nil end)
      |> case do
        [] -> ["default"]
        styles -> styles
      end
      |> Enum.uniq()

    if identifier != nil and !Enum.empty?(formats) do
      %{
        identifier: identifier,
        title: title,
        abstract: abstract,
        formats: formats,
        tile_matrix_sets: tile_matrix_sets,
        styles: styles
      }
    end
  end

  defp make_tile_matrix_sets(tms) do
    tms
    |> Enum.map(&normalize_tile_matrix_set/1)
    |> Enum.reject(fn tms -> tms == nil end)
  end

  defp normalize_tile_matrix_set(tms_data) do
    identifier = normalize_text(tms_data.identifier, nil)
    supported_crs = normalize_text(tms_data.supported_crs, "EPSG:4326")

    matrices =
      tms_data.matrices
      |> Enum.map(&parse_tile_matrix/1)
      |> Enum.reject(fn matrix -> matrix.identifier == nil end)

    if identifier do
      %{
        identifier: identifier,
        supported_crs: supported_crs,
        matrices: matrices
      }
    end
  end

  # Parse individual tile matrix (zoom level) - namespace agnostic
  defp parse_tile_matrix(matrix_node) do
    matrix_data =
      matrix_node
      |> xpath(~x".",
        identifier: ~x"./*[local-name()='Identifier']/text()"s,
        scale_denominator: ~x"./*[local-name()='ScaleDenominator']/text()"s,
        tile_width: ~x"./*[local-name()='TileWidth']/text()"s,
        tile_height: ~x"./*[local-name()='TileHeight']/text()"s,
        matrix_width: ~x"./*[local-name()='MatrixWidth']/text()"s,
        matrix_height: ~x"./*[local-name()='MatrixHeight']/text()"s,
        top_left_corner: ~x"./*[local-name()='TopLeftCorner']/text()"s
      )

    identifier = normalize_text(matrix_data.identifier, nil)
    scale_denominator = parse_float(matrix_data.scale_denominator)
    tile_width = parse_integer(matrix_data.tile_width, 256)
    tile_height = parse_integer(matrix_data.tile_height, 256)
    matrix_width = parse_integer(matrix_data.matrix_width, 1)
    matrix_height = parse_integer(matrix_data.matrix_height, 1)

    top_left_corner =
      (matrix_data.top_left_corner || "0 0")
      |> String.split()
      |> Enum.take(2)
      |> Enum.map(&parse_float/1)
      |> case do
        [x, y] -> {x, y}
        [x] -> {x, 0.0}
        _ -> {0.0, 0.0}
      end

    %{
      identifier: identifier,
      scale_denominator: scale_denominator,
      top_left_corner: top_left_corner,
      tile_width: tile_width,
      tile_height: tile_height,
      matrix_width: matrix_width,
      matrix_height: matrix_height
    }
  end

  defp make_global_formats(fmts) do
    fmts
    |> Enum.map(&normalize_text/1)
    |> Enum.filter(fn fmt -> fmt != nil end)
    |> Enum.uniq()
  end

  # Helper function to normalize text values
  defp normalize_text(nil), do: nil
  defp normalize_text(""), do: nil
  defp normalize_text(text) when is_binary(text), do: String.trim(text)
  defp normalize_text(text, default) when text in [nil, ""], do: default
  defp normalize_text(text, _default) when is_binary(text), do: String.trim(text)

  # Parse string to float with fallback
  defp parse_float(nil), do: 0.0
  defp parse_float(""), do: 0.0

  defp parse_float(str) when is_binary(str) do
    case Float.parse(String.trim(str)) do
      {float, _} -> float
      :error -> 0.0
    end
  end

  # Parse string to integer with fallback
  defp parse_integer(nil, default), do: default
  defp parse_integer("", default), do: default

  defp parse_integer(str, default) when is_binary(str) do
    case Integer.parse(String.trim(str)) do
      {int, _} -> int
      :error -> default
    end
  end
end
