defmodule ExWMTS.WMTSClientIntegrationTest do
  use ExUnit.Case

  alias ExWMTS.WMTSClient

  @moduletag :integration
  @moduletag timeout: 60_000

  @test_services [
    %{
      name: "NASA GIBS",
      base_url: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi"
    },
    %{
      name: "USGS National Map",
      base_url: "https://basemap.nationalmap.gov/arcgis/rest/services/USGSShadedReliefOnly/MapServer/WMTS"
    },
    %{
      name: "German Railway",
      base_url: "https://geoinformation.eisenbahn-bundesamt.de/wmts/dzsf/WMTSCapabilities.xml"
    },
    %{
      name: "US Navy",
      base_url: "https://geoint.nrlssc.navy.mil/osm/wmts/OSM/basemap/Mapnik/OSM_BASEMAP"
    }
  ]

  test "capabilities parsing and GetTile validation" do
    refute Enum.empty?(@test_services)

    Enum.each(@test_services, fn service ->
      case WMTSClient.get_capabilities(service.base_url) do
        {:ok, capabilities} ->
          # Validate capabilities structure according to WMTS standard
          validate_capabilities_structure(capabilities, service.name)

          # Test GetTile with various scenarios
          test_get_tile_operations(service, capabilities)

        {:error, error} ->
          flunk(error)
      end
    end)
  end

  defp validate_capabilities_structure(capabilities, service_name) do
    assert capabilities.service_identification != nil,
           "#{service_name}: Missing ServiceIdentification"

    assert capabilities.service_identification.service_type

    if capabilities.operations_metadata do
      operation_names = capabilities.operations_metadata.operations |> Enum.map(& &1.name)

      assert "GetCapabilities" in operation_names,
             "#{service_name}: GetCapabilities operation must be supported"

      assert "GetTile" in operation_names,
             "#{service_name}: GetTile operation must be supported"
    end

    refute Enum.empty?(capabilities.layers)
    refute Enum.empty?(capabilities.tile_matrix_sets)
  end

  defp test_get_tile_operations(service, capabilities) do
    test_layer =
      capabilities.layers
      |> Enum.shuffle()
      |> Enum.take(1)
      |> hd()

    test_scenarios = generate_test_scenarios(capabilities, test_layer)

    Enum.each(test_scenarios, fn scenario ->
      test_tile_request(service, scenario)
      :timer.sleep(200)
    end)
  end

  defp generate_test_scenarios(capabilities, layer) do
    matrix_set_id = layer.tile_matrix_sets |> Enum.shuffle() |> hd()
    matrix_set = Enum.find(capabilities.tile_matrix_sets, fn ms -> ms.identifier == matrix_set_id end)

    matrix_set_link =
      Enum.find(layer.tile_matrix_set_links || [], fn link ->
        link.tile_matrix_set == matrix_set_id
      end)

    if matrix_set && not Enum.empty?(matrix_set.matrices) do
      # Use lower zoom levels (first 10 matrices) where tiles are more likely to exist
      # High zoom levels often have theoretical extents much larger than actual data
      usable_matrices = matrix_set.matrices |> Enum.take(min(10, length(matrix_set.matrices)))

      usable_matrices
      |> Enum.shuffle()
      |> Enum.take(3)
      |> Enum.with_index(1)
      |> Enum.map(fn {tile_matrix, index} ->
        {min_row, max_row, min_col, max_col} = get_tile_bounds(tile_matrix, matrix_set_link)

        # Generate random coordinates within bounds
        random_row = Enum.random(min_row..max_row)
        random_col = Enum.random(min_col..max_col)

        %{
          name: "random_tile_#{index}",
          params: %{
            layer: layer.identifier,
            style: hd(layer.styles || ["default"]),
            tile_matrix_set: matrix_set_id,
            tile_matrix: tile_matrix.identifier,
            tile_row: random_row,
            tile_col: random_col,
            format: hd(layer.formats)
          }
        }
      end)
    else
      []
    end
  end

  defp get_tile_bounds(tile_matrix, matrix_set_link) do
    matrix_limits =
      if matrix_set_link && matrix_set_link.tile_matrix_set_limits do
        Enum.find(matrix_set_link.tile_matrix_set_limits.tile_matrix_limits || [], fn limits ->
          limits.tile_matrix == tile_matrix.identifier
        end)
      end

    if matrix_limits do
      {
        matrix_limits.min_tile_row,
        matrix_limits.max_tile_row,
        matrix_limits.min_tile_col,
        matrix_limits.max_tile_col
      }
    else
      # No specific limits, use full matrix bounds but cap at reasonable values
      # Many services declare huge theoretical extents but only serve tiles for smaller areas
      max_reasonable_dimension = 1000

      max_row = min(max(0, tile_matrix.matrix_height - 1), max_reasonable_dimension)
      max_col = min(max(0, tile_matrix.matrix_width - 1), max_reasonable_dimension)

      {
        0,
        max_row,
        0,
        max_col
      }
    end
  end

  defp test_tile_request(service, scenario) do
    case WMTSClient.get_capabilities(service.base_url) do
      {:ok, capabilities} ->
        case WMTSClient.get_tile(capabilities, scenario.params) do
          {:ok, tile_data} ->
            validate_tile_response(tile_data, scenario.params.format, scenario.name)

          {:error, error} ->
            flunk("Unexpected error: #{inspect(error)}")
        end

      {:error, caps_error} ->
        flunk("Capabilities error: #{inspect(caps_error)}")
    end
  end

  defp validate_tile_response(tile_data, format, _scenario_name) do
    assert is_binary(tile_data)
    assert byte_size(tile_data) > 0

    detected_format = detect_image_format(tile_data)

    assert format_matches?(format, detected_format),
           "Expected format #{format}, but detected #{detected_format}"
  end

  # Handle ArcGIS-specific formats like "image/jpgpng"
  defp format_matches?("image/jpgpng", detected) when detected in ["image/jpeg", "image/png"], do: true
  defp format_matches?(expected, detected), do: expected == detected

  # Detect image format from binary content
  defp detect_image_format(data) when byte_size(data) < 8, do: :too_small

  defp detect_image_format(data) do
    header = binary_part(data, 0, min(12, byte_size(data)))

    detect_image_type(header) || detect_error_response(header) || :unknown
  end

  defp detect_image_type(header) do
    case header do
      # PNG: 89 50 4E 47 0D 0A 1A 0A
      <<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>> -> "image/png"
      # JPEG: FF D8
      <<255, 216, _rest::binary>> -> "image/jpeg"
      # WebP: RIFF....WEBP
      <<"RIFF", _size::32-little, "WEBP", _rest::binary>> -> "image/webp"
      # GIF87a or GIF89a
      <<"GIF87a", _rest::binary>> -> "image/gif"
      <<"GIF89a", _rest::binary>> -> "image/gif"
      _ -> nil
    end
  end

  defp detect_error_response(header) do
    case header do
      # Check for HTML/XML error responses
      <<"<!DOCTYPE", _rest::binary>> -> :html_error
      <<"<html", _rest::binary>> -> :html_error
      <<"<?xml", _rest::binary>> -> :xml_error
      <<"<Capabilities", _rest::binary>> -> :capabilities_xml_error
      _ -> nil
    end
  end
end
