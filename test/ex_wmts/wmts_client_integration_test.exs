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

  test "against known endpoints" do
    refute Enum.empty?(@test_services)

    Enum.each(@test_services, fn service ->
      with {:ok, capabilities} <- WMTSClient.get_capabilities(service.base_url) do
        test_layers =
          capabilities.layers
          |> Enum.shuffle()
          |> Enum.take(2)

        Enum.each(
          test_layers,
          fn layer ->
            params = find_params(capabilities, layer)

            if params.format do
              :timer.sleep(500)

              WMTSClient.get_tile(service.base_url, params)
              |> case do
                {:error, e} ->
                  flunk(e)

                other ->
                  other
              end
            end
          end
        )
      end
    end)
  end

  defp find_params(capabilities, layer) do
    matrix_set_to_use = layer.tile_matrix_sets |> Enum.shuffle() |> hd()

    matrix_set =
      Enum.filter(capabilities.tile_matrix_sets, fn %{identifier: id} -> id == matrix_set_to_use end)
      |> hd()

    format = Enum.shuffle(layer.formats) |> Enum.at(0)
    tile_matrix = matrix_set.matrices |> Enum.take(2) |> Enum.shuffle() |> hd()
    random_row = floor((tile_matrix.matrix_height - 1) / 2)
    random_col = floor((tile_matrix.matrix_width - 1) / 2)

    %{
      layer: layer.identifier,
      style: Enum.at(layer.styles, 0, "default"),
      tile_matrix_set: matrix_set_to_use,
      tile_matrix: tile_matrix.identifier,
      tile_row: random_row,
      tile_col: random_col,
      format: format
    }
  end
end
