defmodule ExWMTS.CapabilitiesParserTest do
  use ExUnit.Case

  alias ExWMTS.CapabilitiesParser

  @moduletag :parser

  describe "Capabilities parser with diverse XML samples" do
    test "parses OGC standard spec" do
      {:ok, _capabilities} =
        "test/support/capabilities/ogc_standard_1.xml"
        |> File.read!()
        |> CapabilitiesParser.parse()
        |> IO.inspect()
    end

    test "parses NASA GIBS capabilities" do
      {:ok, capabilities} =
        "test/support/capabilities/nasa_gibs.xml"
        |> File.read!()
        |> CapabilitiesParser.parse()

      %{
        service_identification: %ExWMTS.ServiceIdentification{
          title: "NASA Global Imagery Browse Services for EOSDIS",
          service_type: "OGC WMTS"
        },
        operations_metadata: %ExWMTS.OperationsMetadata{
          operations: [
            %ExWMTS.Operation{name: "GetCapabilities", dcp: get_cap_dcp},
            %ExWMTS.Operation{name: "GetTile", dcp: get_tile_dcp}
          ]
        },
        layers: layers,
        tile_matrix_sets: tms,
        formats: formats
      } = capabilities

      assert %ExWMTS.DCP{
               http: %ExWMTS.HTTP{
                 get: [
                   %ExWMTS.HTTPMethod{
                     href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/1.0.0/WMTSCapabilities.xml",
                     constraints: [%ExWMTS.Constraint{name: "GetEncoding", allowed_values: ["RESTful"]}]
                   },
                   %ExWMTS.HTTPMethod{
                     href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi?",
                     constraints: [%ExWMTS.Constraint{name: "GetEncoding", allowed_values: ["KVP"]}]
                   }
                 ],
                 post: nil
               }
             } = get_cap_dcp

      assert %ExWMTS.DCP{
               http: %ExWMTS.HTTP{
                 get: [
                   %ExWMTS.HTTPMethod{
                     href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/",
                     constraints: [%ExWMTS.Constraint{name: "GetEncoding", allowed_values: ["RESTful"]}]
                   },
                   %ExWMTS.HTTPMethod{
                     href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi?",
                     constraints: [%ExWMTS.Constraint{name: "GetEncoding", allowed_values: ["KVP"]}]
                   }
                 ],
                 post: nil
               }
             } = get_tile_dcp

      assert length(capabilities.layers) == 1194
      assert "image/png" in formats
      refute Enum.empty?(tms)
      refute Enum.empty?(layers)

      merra_layer = Enum.find(capabilities.layers, &(&1.identifier == "MERRA2_2m_Air_Temperature_Monthly"))
      assert %{title: title, tile_matrix_sets: ["2km" | _], formats: ["image/png" | _]} = merra_layer
      assert title =~ "Air Temperature"

      assert %ExWMTS.Layer{
               tile_matrix_set_links: [
                 %ExWMTS.TileMatrixSetLink{
                   tile_matrix_set: "2km",
                   tile_matrix_set_limits: nil
                 }
               ]
             } = merra_layer

      goes_east_layer = Enum.find(capabilities.layers, &(&1.identifier == "GOES-East_ABI_Air_Mass"))
      assert goes_east_layer != nil

      assert %ExWMTS.Layer{
               tile_matrix_set_links: [
                 %ExWMTS.TileMatrixSetLink{
                   tile_matrix_set: "2km",
                   tile_matrix_set_limits: %ExWMTS.TileMatrixSetLimits{
                     tile_matrix_set: "2km",
                     tile_matrix_limits: limits
                   }
                 }
               ]
             } = goes_east_layer

      refute Enum.empty?(limits)
      first_limit = List.first(limits)

      assert %ExWMTS.TileMatrixLimits{
               tile_matrix: tile_matrix_id,
               min_tile_row: min_row,
               max_tile_row: max_row,
               min_tile_col: min_col,
               max_tile_col: max_col
             } = first_limit

      assert is_binary(tile_matrix_id)
      assert is_integer(min_row) and min_row >= 0
      assert is_integer(max_row) and max_row >= min_row
      assert is_integer(min_col) and min_col >= 0
      assert is_integer(max_col) and max_col >= min_col
    end

    test "parses USGS National Map capabilities" do
      {:ok, capabilities} =
        "test/support/capabilities/usgs_nationalmap.xml"
        |> File.read!()
        |> CapabilitiesParser.parse()

      %{
        service_identification: %ExWMTS.ServiceIdentification{
          title: "USGSShadedReliefOnly",
          service_type: "OGC WMTS"
        },
        layers: [
          %ExWMTS.Layer{
            identifier: "USGSShadedReliefOnly",
            tile_matrix_sets: matrix_sets
          }
        ],
        tile_matrix_sets: [_, _] = two_matrix_sets,
        formats: ["image/jpgpng"]
      } = capabilities

      assert "default028mm" in matrix_sets
      assert "GoogleMapsCompatible" in matrix_sets

      gm_tms = Enum.find(two_matrix_sets, &(&1.identifier == "GoogleMapsCompatible"))

      assert %ExWMTS.TileMatrixSet{
               identifier: "GoogleMapsCompatible",
               supported_crs: crs,
               matrices: matrices
             } = gm_tms

      assert crs =~ "3857"
      assert length(matrices) == 19

      [%ExWMTS.TileMatrix{identifier: "0"} = level_0, %ExWMTS.TileMatrix{identifier: "1"} = level_1 | _] =
        Enum.sort_by(matrices, &String.to_integer(&1.identifier))

      assert level_0.scale_denominator > level_1.scale_denominator
      assert level_1.matrix_width == level_0.matrix_width * 2
    end

    test "parses French Geoportal capabilities" do
      {:ok, capabilities} =
        "test/support/capabilities/french_geoportal.xml"
        |> File.read!()
        |> CapabilitiesParser.parse()

      %{
        service_identification: %ExWMTS.ServiceIdentification{
          service_type: "OGC WMTS"
        },
        layers: layers,
        tile_matrix_sets: matrix_sets,
        formats: formats
      } = capabilities

      assert length(layers) == 655
      assert length(matrix_sets) == 50
      assert length(formats) == 3
      assert Enum.all?(formats, &String.contains?(&1, "image/"))

      sample_layer =
        Enum.find(layers, fn layer ->
          case layer.tile_matrix_set_links do
            [%ExWMTS.TileMatrixSetLink{tile_matrix_set_limits: limits}] when not is_nil(limits) ->
              case limits.tile_matrix_limits do
                matrix_limits when is_list(matrix_limits) and length(matrix_limits) > 10 -> true
                _ -> false
              end

            _ ->
              false
          end
        end)

      assert sample_layer != nil

      assert %ExWMTS.Layer{
               tile_matrix_set_links: [
                 %ExWMTS.TileMatrixSetLink{
                   tile_matrix_set: tile_matrix_set_id,
                   tile_matrix_set_limits: %ExWMTS.TileMatrixSetLimits{
                     tile_matrix_set: same_id,
                     tile_matrix_limits: detailed_limits
                   }
                 }
               ]
             } = sample_layer

      assert tile_matrix_set_id == same_id
      assert length(detailed_limits) > 10

      limit_matrices = detailed_limits |> Enum.map(&String.to_integer(&1.tile_matrix)) |> Enum.sort()
      assert limit_matrices == Enum.to_list(0..11)

      matrix_11_limit = Enum.find(detailed_limits, &(&1.tile_matrix == "11"))
      assert matrix_11_limit != nil

      assert %ExWMTS.TileMatrixLimits{
               tile_matrix: "11",
               min_tile_row: min_row,
               max_tile_row: max_row,
               min_tile_col: min_col,
               max_tile_col: max_col
             } = matrix_11_limit

      assert min_row >= 680 and min_row <= 690
      assert max_row >= 770 and max_row <= 780
      assert min_col >= 980 and min_col <= 1000
      assert max_col >= 1080 and max_col <= 1100
    end

    test "parses German Railway capabilities" do
      {:ok, capabilities} =
        "test/support/capabilities/german_railway.xml"
        |> File.read!()
        |> CapabilitiesParser.parse()

      %{
        service_identification: %ExWMTS.ServiceIdentification{
          title:
            "(WMTS) Geoinformation Deutsches Zentrum für Schienenverkehrsforschung beim Eisenbahn-Bundesamt (DZSF)",
          service_type: "OGC WMTS"
        },
        layers: layers,
        formats: ["image/png"]
      } = capabilities

      hangrutschung_layer = Enum.find(layers, &(&1.identifier == "hangrutschungsgefaehrdung_wmts"))

      assert length(layers) == 10
      assert hangrutschung_layer != nil
      assert hangrutschung_layer.title == "Hangrutschungsgefährdung WMTS"
      assert hangrutschung_layer.identifier == "hangrutschungsgefaehrdung_wmts"
      assert hangrutschung_layer.formats == ["image/png"]
      assert hangrutschung_layer.tile_matrix_sets == ["wmtsgrid"]
      assert hangrutschung_layer.keywords == ["Hangrutschungsgefährdung WMTS"]

      assert hangrutschung_layer.wgs84_bounding_box == %ExWMTS.WGS84BoundingBox{
               lower_corner: {4.34738512723, 46.7961383601},
               upper_corner: {16.9787143025, 55.3482568074}
             }

      assert length(hangrutschung_layer.metadata) == 1
      assert hd(hangrutschung_layer.metadata).href =~ "geoinformation.eisenbahn-bundesamt.de"

      assert length(hangrutschung_layer.resource_urls) == 2
      tile_url = Enum.find(hangrutschung_layer.resource_urls, &(&1.resource_type == "tile"))
      assert tile_url.format == "image/png"
      assert tile_url.template =~ "hangrutschungsgefaehrdung_wmts"

      assert %ExWMTS.Layer{
               tile_matrix_set_links: [
                 %ExWMTS.TileMatrixSetLink{
                   tile_matrix_set: "wmtsgrid",
                   tile_matrix_set_limits: nil
                 }
               ]
             } = hangrutschung_layer
    end

    test "parses US Navy capabilities" do
      {:ok, capabilities} =
        "test/support/capabilities/us_navy.xml"
        |> File.read!()
        |> CapabilitiesParser.parse()

      %{
        service_identification: %ExWMTS.ServiceIdentification{
          title: "OSM_WMTS_Server",
          abstract: "WMTS-based access to Open Street Map data",
          service_type: "WMTS",
          service_type_version: "1.0.0"
        },
        operations_metadata: %ExWMTS.OperationsMetadata{
          operations: operations
        },
        layers: [
          %ExWMTS.Layer{
            identifier: "OSM_BASEMAP",
            title: "OSM_BASEMAP",
            formats: ["image/png", "image/jpeg"],
            tile_matrix_sets: [
              "GlobalCRS84Scale",
              "NRLTileScheme",
              "NRLTileScheme256",
              "GlobalCRS84Pixel",
              "GoogleCRS84Quad",
              "GoogleMapsCompatible",
              "EPSG3395TiledMercator"
            ],
            styles: ["default"]
          }
        ],
        tile_matrix_sets: tile_matrix_sets
      } = capabilities

      assert length(tile_matrix_sets) == 7

      global_crs84_tms = Enum.find(tile_matrix_sets, &(&1.identifier == "GlobalCRS84Scale"))

      assert %ExWMTS.TileMatrixSet{
               identifier: "GlobalCRS84Scale",
               supported_crs: "urn:ogc:def:crs:OGC:1.3:CRS84",
               matrices: global_crs84_matrices
             } = global_crs84_tms

      assert length(global_crs84_matrices) == 21

      level_0 = Enum.find(global_crs84_matrices, &(&1.identifier == "0"))
      assert level_0.scale_denominator == 500_000_000.0
      assert level_0.matrix_width == 2
      assert level_0.matrix_height == 1

      level_20 = Enum.find(global_crs84_matrices, &(&1.identifier == "20"))
      assert level_20.scale_denominator == 100.0
      assert level_20.matrix_width == 5_004_373
      assert level_20.matrix_height == 2_502_187

      gm_tms = Enum.find(tile_matrix_sets, &(&1.identifier == "GoogleMapsCompatible"))

      assert %ExWMTS.TileMatrixSet{
               identifier: "GoogleMapsCompatible",
               supported_crs: crs,
               matrices: gm_matrices
             } = gm_tms

      assert crs =~ "3857"
      assert length(gm_matrices) == 21

      gm_level_0 = Enum.find(gm_matrices, &(&1.identifier == "0"))
      assert gm_level_0.matrix_width == 1
      assert gm_level_0.matrix_height == 1
      assert gm_level_0.top_left_corner == {-20_037_508.34279, 20_037_508.34279}

      nrl_tms = Enum.find(tile_matrix_sets, &(&1.identifier == "NRLTileScheme"))
      nrl256_tms = Enum.find(tile_matrix_sets, &(&1.identifier == "NRLTileScheme256"))

      assert length(nrl_tms.matrices) == 22
      assert length(nrl256_tms.matrices) == 22

      nrl_level_1 = Enum.find(nrl_tms.matrices, &(&1.identifier == "1"))
      nrl256_level_1 = Enum.find(nrl256_tms.matrices, &(&1.identifier == "1"))

      # NRLTileScheme uses 512px tiles
      assert nrl_level_1.tile_width == 512
      # NRLTileScheme256 uses 256px tiles
      assert nrl256_level_1.tile_width == 256

      assert length(operations) == 3
      get_capabilities_op = Enum.find(operations, &(&1.name == "GetCapabilities"))
      get_tile_op = Enum.find(operations, &(&1.name == "GetTile"))

      assert get_capabilities_op != nil
      assert get_tile_op != nil
      assert get_capabilities_op.dcp.http.get != []
      assert get_tile_op.dcp.http.get != []
    end

    test "handles minimal XML structure" do
      minimal_xml = """
      <Capabilities>
        <ServiceIdentification>
          <Title>Test Service</Title>
          <ServiceType>OGC WMTS</ServiceType>
          <ServiceTypeVersion>1.0.0</ServiceTypeVersion>
        </ServiceIdentification>
        <Contents>
          <Layer>
            <Identifier>test_layer</Identifier>
            <Title>Test Layer</Title>
            <Format>image/png</Format>
            <TileMatrixSetLink>
              <TileMatrixSet>test_matrix</TileMatrixSet>
            </TileMatrixSetLink>
            <Style>
              <Identifier>default</Identifier>
            </Style>
          </Layer>
          <TileMatrixSet>
            <Identifier>test_matrix</Identifier>
            <SupportedCRS>EPSG:3857</SupportedCRS>
            <TileMatrix>
              <Identifier>0</Identifier>
              <ScaleDenominator>559082264</ScaleDenominator>
              <TopLeftCorner>-20037508 20037508</TopLeftCorner>
              <TileWidth>256</TileWidth>
              <TileHeight>256</TileHeight>
              <MatrixWidth>1</MatrixWidth>
              <MatrixHeight>1</MatrixHeight>
            </TileMatrix>
          </TileMatrixSet>
        </Contents>
      </Capabilities>
      """

      {:ok,
       %{
         service_identification: %ExWMTS.ServiceIdentification{
           title: "Test Service",
           abstract: "",
           service_type: "OGC WMTS",
           service_type_version: "1.0.0"
         },
         layers: [
           %ExWMTS.Layer{
             identifier: "test_layer",
             title: "Test Layer",
             abstract: "",
             formats: ["image/png"],
             tile_matrix_sets: ["test_matrix"],
             styles: ["default"]
           }
         ],
         tile_matrix_sets: [
           %ExWMTS.TileMatrixSet{
             identifier: "test_matrix",
             supported_crs: "EPSG:3857",
             matrices: [
               %ExWMTS.TileMatrix{
                 identifier: "0",
                 scale_denominator: 559_082_264.0,
                 matrix_width: 1,
                 top_left_corner: {-20_037_508.0, 20_037_508.0},
                 matrix_height: 1,
                 tile_height: 256,
                 tile_width: 256
               }
             ]
           }
         ]
       }}

      {:ok, capabilities} = CapabilitiesParser.parse(minimal_xml)
      assert Map.has_key?(capabilities, :formats)
      assert capabilities.formats == ["image/png"]
    end
  end
end
