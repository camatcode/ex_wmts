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
    end

    test "parses NASA GIBS capabilities" do
      {:ok, capabilities} =
        "test/support/capabilities/nasa_gibs.xml"
        |> File.read!()
        |> CapabilitiesParser.parse()

      %{
        service_identification: %{title: "NASA Global Imagery Browse Services for EOSDIS", service_type: "OGC WMTS"},
        layers: layers,
        tile_matrix_sets: tms,
        formats: formats
      } = capabilities

      assert length(capabilities.layers) > 1000
      assert "image/png" in formats
      refute Enum.empty?(tms)
      refute Enum.empty?(layers)

      merra_layer = Enum.find(capabilities.layers, &(&1.identifier == "MERRA2_2m_Air_Temperature_Monthly"))
      assert %{title: title, tile_matrix_sets: ["2km" | _], formats: ["image/png" | _]} = merra_layer
      assert title =~ "Air Temperature"
    end

    test "parses USGS National Map capabilities" do
      {:ok, capabilities} =
        "test/support/capabilities/usgs_nationalmap.xml"
        |> File.read!()
        |> CapabilitiesParser.parse()

      %{
        service_identification: %{title: "USGSShadedReliefOnly", service_type: "OGC WMTS"},
        layers: [%{identifier: "USGSShadedReliefOnly", tile_matrix_sets: matrix_sets}],
        tile_matrix_sets: [_, _] = two_matrix_sets,
        formats: ["image/jpgpng"]
      } = capabilities

      assert "default028mm" in matrix_sets
      assert "GoogleMapsCompatible" in matrix_sets

      # Check GoogleMapsCompatible has proper Web Mercator structure
      gm_tms = Enum.find(two_matrix_sets, &(&1.identifier == "GoogleMapsCompatible"))
      assert %{supported_crs: crs, matrices: matrices} = gm_tms
      assert crs =~ "3857"
      assert length(matrices) > 15

      # Validate matrix progression (level 0 -> level 1)
      [%{identifier: "0"} = level_0, %{identifier: "1"} = level_1 | _] =
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
        service_identification: %{service_type: "OGC WMTS"},
        layers: layers,
        tile_matrix_sets: matrix_sets,
        formats: formats
      } = capabilities

      assert length(layers) == 655
      assert length(matrix_sets) == 50
      assert length(formats) == 3
      assert Enum.all?(formats, &String.contains?(&1, "image/"))
    end

    test "parses German Railway capabilities" do
      {:ok, capabilities} =
        "test/support/capabilities/german_railway.xml"
        |> File.read!()
        |> CapabilitiesParser.parse()

      %{
        service_identification: %{
          title:
            "(WMTS) Geoinformation Deutsches Zentrum für Schienenverkehrsforschung beim Eisenbahn-Bundesamt (DZSF)",
          service_type: "OGC WMTS"
        },
        layers: layers,
        formats: ["image/png"]
      } = capabilities

      known_layer = %ExWMTS.Layer{
        title: "Hangrutschungsgefährdung WMTS",
        abstract:
          "Der Datensatz stellt die Gefährdung der Schieneninfrastruktur durch Hangrutschungen räumlich differenziert dar. Dieses Produkt der Hangrutschungsgefährdung ist das Ergebnis des Forschungsprojektes „Erstellung einer ingenieurgeologischen Gefahrenhinweiskarte zu Hang- und Böschungsrutschungen entlang des deutschen Schienennetzes“ des Eisenbahn-Bundesamtes im Rahmen der Arbeiten des BMDV-Expertennetzwerks im Themenfeld Klimawandelfolgen und Anpassung (bmdv-expertennetzwerk.de). Die Sachinformationen und Gefährdungsklassen werden ausschließlich für den Bereich der Schieneninfrastruktur bereitgestellt. Datengrundlage hierfür ist der Datensatz ‚geo-strecke‘, welcher von der Deutschen Bahn (DB) unter der Lizenz Creative Commons Attribution 4.0 International (CC BY 4.0) bereitgestellt wird (http://data.deutschebahn.com/dataset/geo-strecke). Dargestellt sind die potenziellen Gefährdungsbereiche und Puffer (0 m und 50 m) bezogen auf die Gefahrenklassen größer bzw. gleich 10) (s. Abschlussbericht „Erstellung einer ingenieurgeologischen Gefahrenhinweiskarte zu Hang- und Böschungsrutschungen entlang des deutschen Schienennetzes“ - Eisenbahn-Bundesamt: 11vb/018-0099#22; S. 100). Das Attribut „Gef_ber“ wurde hinzugefügt und in drei Klassen unterteilt in Bereiche der Gefahrenklasse >= 10 wurde der direkte Einflussbereich (0) sowie ein Puffer von 50 m (50) berücksichtigt. Bereiche mit einer geringeren errechneten Gefahrenklasse oder außerhalb des Puffers sind mit ‚999‘ kodiert.",
        identifier: "hangrutschungsgefaehrdung_wmts",
        tile_matrix_sets: ["wmtsgrid"],
        formats: ["image/png"],
        styles: ["hangrutschungsgefaehrdung_wmts"]
      }

      assert length(layers) == 10
      assert known_layer in layers
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
        layers: [
          %ExWMTS.Layer{
            identifier: "OSM_BASEMAP",
            title: "OSM_BASEMAP",
            abstract: "",
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
        tile_matrix_sets: [
          %{
            identifier: "GlobalCRS84Scale",
            supported_crs: "urn:ogc:def:crs:OGC:1.3:CRS84",
            matrices: [
              %{
                identifier: "0",
                scale_denominator: 500_000_000.0,
                matrix_width: 2,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "1",
                scale_denominator: 250_000_000.0,
                matrix_width: 3,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "2",
                scale_denominator: 100_000_000.0,
                matrix_width: 6,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 3,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "3",
                scale_denominator: 50_000_000.0,
                matrix_width: 11,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 6,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "4",
                scale_denominator: 25_000_000.0,
                matrix_width: 21,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 11,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "5",
                scale_denominator: 10_000_000.0,
                matrix_width: 51,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 26,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "6",
                scale_denominator: 5_000_000.0,
                matrix_width: 101,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 51,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "7",
                scale_denominator: 2_500_000.0,
                matrix_width: 201,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 101,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "8",
                scale_denominator: 1_000_000.0,
                matrix_width: 501,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 251,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "9",
                scale_denominator: 500_000.0,
                matrix_width: 1001,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 501,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "10",
                scale_denominator: 250_000.0,
                matrix_width: 2002,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1001,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "11",
                scale_denominator: 100_000.0,
                matrix_width: 5005,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2503,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "12",
                scale_denominator: 50_000.0,
                matrix_width: 10_009,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 5005,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "13",
                scale_denominator: 25_000.0,
                matrix_width: 20_018,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 10_009,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "14",
                scale_denominator: 10_000.0,
                matrix_width: 50_044,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 25_022,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "15",
                scale_denominator: 5000.0,
                matrix_width: 100_088,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 50_044,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "16",
                scale_denominator: 2500.0,
                matrix_width: 200_175,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 100_088,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "17",
                scale_denominator: 1000.0,
                matrix_width: 500_438,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 250_219,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "18",
                scale_denominator: 500.0,
                matrix_width: 1_000_875,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 500_438,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "19",
                scale_denominator: 250.0,
                matrix_width: 2_001_750,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1_000_875,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "20",
                scale_denominator: 100.0,
                matrix_width: 5_004_373,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2_502_187,
                tile_height: 256,
                tile_width: 256
              }
            ]
          },
          %{
            identifier: "GlobalCRS84Pixel",
            supported_crs: "urn:ogc:def:crs:OGC:1.3:CRS84",
            matrices: [
              %{
                identifier: "0",
                scale_denominator: 795_139_219.9519541,
                matrix_width: 1,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "1",
                scale_denominator: 397_569_609.9759771,
                matrix_width: 2,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "2",
                scale_denominator: 198_784_804.9879885,
                matrix_width: 3,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "3",
                scale_denominator: 132_523_203.3253257,
                matrix_width: 5,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 3,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "4",
                scale_denominator: 66_261_601.66266284,
                matrix_width: 9,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 5,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "5",
                scale_denominator: 33_130_800.83133142,
                matrix_width: 17,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 9,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "6",
                scale_denominator: 13_252_320.33253257,
                matrix_width: 43,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 22,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "7",
                scale_denominator: 6_626_160.166266284,
                matrix_width: 85,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 43,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "8",
                scale_denominator: 3_313_080.083133142,
                matrix_width: 169,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 85,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "9",
                scale_denominator: 1_656_540.041566571,
                matrix_width: 338,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 169,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "10",
                scale_denominator: 552_180.0138555235,
                matrix_width: 1013,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 507,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "11",
                scale_denominator: 331_308.0083133142,
                matrix_width: 1688,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 844,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "12",
                scale_denominator: 110_436.0027711047,
                matrix_width: 5063,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2532,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "13",
                scale_denominator: 55_218.00138555237,
                matrix_width: 10_125,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 5063,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "14",
                scale_denominator: 33_130.80083133142,
                matrix_width: 16_875,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 8438,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "15",
                scale_denominator: 11_043.60027711047,
                matrix_width: 50_625,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 25_313,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "16",
                scale_denominator: 3313.080083133142,
                matrix_width: 168_750,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 84_375,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "17",
                scale_denominator: 1104.360027711047,
                matrix_width: 506_250,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 253_125,
                tile_height: 256,
                tile_width: 256
              }
            ]
          },
          %{
            identifier: "GoogleCRS84Quad",
            supported_crs: "urn:ogc:def:crs:OGC:1.3:CRS84",
            matrices: [
              %{
                identifier: "0",
                scale_denominator: 559_082_264.0287178,
                matrix_width: 1,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 1,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "1",
                scale_denominator: 279_541_132.0143589,
                matrix_width: 2,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 2,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "2",
                scale_denominator: 139_770_566.0071794,
                matrix_width: 4,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 4,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "3",
                scale_denominator: 69_885_283.00358972,
                matrix_width: 8,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 8,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "4",
                scale_denominator: 34_942_641.50179486,
                matrix_width: 16,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 16,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "5",
                scale_denominator: 17_471_320.75089743,
                matrix_width: 32,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 32,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "6",
                scale_denominator: 8_735_660.375448715,
                matrix_width: 64,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 64,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "7",
                scale_denominator: 4_367_830.187724357,
                matrix_width: 128,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 128,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "8",
                scale_denominator: 2_183_915.093862179,
                matrix_width: 256,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 256,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "9",
                scale_denominator: 1_091_957.546931089,
                matrix_width: 512,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 512,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "10",
                scale_denominator: 545_978.7734655447,
                matrix_width: 1024,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 1024,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "11",
                scale_denominator: 272_989.3867327723,
                matrix_width: 2048,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 2048,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "12",
                scale_denominator: 136_494.6933663862,
                matrix_width: 4096,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 4096,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "13",
                scale_denominator: 68_247.34668319309,
                matrix_width: 8192,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 8192,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "14",
                scale_denominator: 34_123.67334159654,
                matrix_width: 16_384,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 16_384,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "15",
                scale_denominator: 17_061.83667079827,
                matrix_width: 32_768,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 32_768,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "16",
                scale_denominator: 8530.918335399136,
                matrix_width: 65_536,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 65_536,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "17",
                scale_denominator: 4265.459167699568,
                matrix_width: 131_072,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 131_072,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "18",
                scale_denominator: 2132.729583849784,
                matrix_width: 262_144,
                top_left_corner: {-180.0, 180.0},
                matrix_height: 262_144,
                tile_height: 256,
                tile_width: 256
              }
            ]
          },
          %{
            identifier: "GoogleMapsCompatible",
            supported_crs: "urn:ogc:def:crs:EPSG:6.18:3:3857",
            matrices: [
              %{
                identifier: "0",
                scale_denominator: 559_082_264.0287178,
                matrix_width: 1,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 1,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "1",
                scale_denominator: 279_541_132.0143589,
                matrix_width: 2,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 2,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "2",
                scale_denominator: 139_770_566.00717944,
                matrix_width: 4,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 4,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "3",
                scale_denominator: 69_885_283.00358972,
                matrix_width: 8,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 8,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "4",
                scale_denominator: 34_942_641.50179486,
                matrix_width: 16,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 16,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "5",
                scale_denominator: 17_471_320.75089743,
                matrix_width: 32,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 32,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "6",
                scale_denominator: 8_735_660.375448715,
                matrix_width: 64,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 64,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "7",
                scale_denominator: 4_367_830.1877243575,
                matrix_width: 128,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 128,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "8",
                scale_denominator: 2_183_915.0938621787,
                matrix_width: 256,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 256,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "9",
                scale_denominator: 1_091_957.5469310894,
                matrix_width: 512,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 512,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "10",
                scale_denominator: 545_978.7734655447,
                matrix_width: 1024,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 1024,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "11",
                scale_denominator: 272_989.38673277234,
                matrix_width: 2048,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 2048,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "12",
                scale_denominator: 136_494.69336638617,
                matrix_width: 4096,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 4096,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "13",
                scale_denominator: 68_247.34668319309,
                matrix_width: 8192,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 8192,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "14",
                scale_denominator: 34_123.67334159654,
                matrix_width: 16_384,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 16_384,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "15",
                scale_denominator: 17_061.83667079827,
                matrix_width: 32_768,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 32_768,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "16",
                scale_denominator: 8530.918335399136,
                matrix_width: 65_536,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 65_536,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "17",
                scale_denominator: 4265.459167699568,
                matrix_width: 131_072,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 131_072,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "18",
                scale_denominator: 2132.729583849784,
                matrix_width: 262_144,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 262_144,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "19",
                scale_denominator: 1066.364791924892,
                matrix_width: 524_288,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 524_288,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "20",
                scale_denominator: 533.182395962446,
                matrix_width: 1_048_576,
                top_left_corner: {-20_037_508.34279, 20_037_508.34279},
                matrix_height: 1_048_576,
                tile_height: 256,
                tile_width: 256
              }
            ]
          },
          %{
            identifier: "NRLTileScheme",
            supported_crs: "urn:ogc:def:crs:OGC:1.3:CRS84",
            matrices: [
              %{
                identifier: "1",
                scale_denominator: 147_748_799.285417,
                matrix_width: 2,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "2",
                scale_denominator: 73_874_399.6427085,
                matrix_width: 4,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "3",
                scale_denominator: 36_937_199.82135425,
                matrix_width: 8,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 4,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "4",
                scale_denominator: 18_468_599.910677124,
                matrix_width: 16,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 8,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "5",
                scale_denominator: 9_234_299.955338562,
                matrix_width: 32,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 16,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "6",
                scale_denominator: 4_617_149.977669281,
                matrix_width: 64,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 32,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "7",
                scale_denominator: 2_308_574.9888346405,
                matrix_width: 128,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 64,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "8",
                scale_denominator: 1_154_287.4944173202,
                matrix_width: 256,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 128,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "9",
                scale_denominator: 577_143.7472086601,
                matrix_width: 512,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 256,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "10",
                scale_denominator: 288_571.87360433006,
                matrix_width: 1024,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 512,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "11",
                scale_denominator: 144_285.93680216503,
                matrix_width: 2048,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1024,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "12",
                scale_denominator: 72_142.96840108251,
                matrix_width: 4096,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2048,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "13",
                scale_denominator: 36_071.48420054126,
                matrix_width: 8192,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 4096,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "14",
                scale_denominator: 18_035.74210027063,
                matrix_width: 16_384,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 8192,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "15",
                scale_denominator: 9017.871050135314,
                matrix_width: 32_768,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 16_384,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "16",
                scale_denominator: 4508.935525067657,
                matrix_width: 65_536,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 32_768,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "17",
                scale_denominator: 2254.4677625338286,
                matrix_width: 131_072,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 65_536,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "18",
                scale_denominator: 1127.2338812669143,
                matrix_width: 262_144,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 131_072,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "19",
                scale_denominator: 563.6169406334571,
                matrix_width: 524_288,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 262_144,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "20",
                scale_denominator: 281.8084703167286,
                matrix_width: 1_048_576,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 524_288,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "21",
                scale_denominator: 140.9042351583643,
                matrix_width: 2_097_152,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1_048_576,
                tile_height: 512,
                tile_width: 512
              },
              %{
                identifier: "22",
                scale_denominator: 70.45211757918214,
                matrix_width: 4_194_304,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2_097_152,
                tile_height: 512,
                tile_width: 512
              }
            ]
          },
          %{
            identifier: "NRLTileScheme256",
            supported_crs: "urn:ogc:def:crs:OGC:1.3:CRS84",
            matrices: [
              %{
                identifier: "1",
                scale_denominator: 279_541_132.0143589,
                matrix_width: 2,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "2",
                scale_denominator: 139_770_566.00717944,
                matrix_width: 4,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "3",
                scale_denominator: 69_885_283.00358972,
                matrix_width: 8,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 4,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "4",
                scale_denominator: 34_942_641.50179486,
                matrix_width: 16,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 8,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "5",
                scale_denominator: 17_471_320.75089743,
                matrix_width: 32,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 16,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "6",
                scale_denominator: 8_735_660.375448715,
                matrix_width: 64,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 32,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "7",
                scale_denominator: 4_367_830.1877243575,
                matrix_width: 128,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 64,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "8",
                scale_denominator: 2_183_915.0938621787,
                matrix_width: 256,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 128,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "9",
                scale_denominator: 1_091_957.5469310894,
                matrix_width: 512,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 256,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "10",
                scale_denominator: 545_978.7734655447,
                matrix_width: 1024,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 512,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "11",
                scale_denominator: 272_989.38673277234,
                matrix_width: 2048,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1024,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "12",
                scale_denominator: 136_494.69336638617,
                matrix_width: 4096,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2048,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "13",
                scale_denominator: 68_247.34668319309,
                matrix_width: 8192,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 4096,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "14",
                scale_denominator: 34_123.67334159654,
                matrix_width: 16_384,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 8192,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "15",
                scale_denominator: 17_061.83667079827,
                matrix_width: 32_768,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 16_384,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "16",
                scale_denominator: 8530.918335399136,
                matrix_width: 65_536,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 32_768,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "17",
                scale_denominator: 4265.459167699568,
                matrix_width: 131_072,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 65_536,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "18",
                scale_denominator: 2132.729583849784,
                matrix_width: 262_144,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 131_072,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "19",
                scale_denominator: 1066.364791924892,
                matrix_width: 524_288,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 262_144,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "20",
                scale_denominator: 533.182395962446,
                matrix_width: 1_048_576,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 524_288,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "21",
                scale_denominator: 266.591197981223,
                matrix_width: 2_097_152,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 1_048_576,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "22",
                scale_denominator: 133.2955989906115,
                matrix_width: 4_194_304,
                top_left_corner: {-180.0, 90.0},
                matrix_height: 2_097_152,
                tile_height: 256,
                tile_width: 256
              }
            ]
          },
          %{
            identifier: "EPSG3395TiledMercator",
            supported_crs: "EPSG:3395",
            matrices: [
              %{
                identifier: "0",
                scale_denominator: 559_082_264.028718,
                matrix_width: 1,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 1,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "1",
                scale_denominator: 279_541_132.014359,
                matrix_width: 2,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 2,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "2",
                scale_denominator: 139_770_566.0071795,
                matrix_width: 4,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 4,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "3",
                scale_denominator: 69_885_283.00358975,
                matrix_width: 8,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 8,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "4",
                scale_denominator: 34_942_641.501794875,
                matrix_width: 16,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 16,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "5",
                scale_denominator: 17_471_320.750897437,
                matrix_width: 32,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 32,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "6",
                scale_denominator: 8_735_660.375448719,
                matrix_width: 64,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 64,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "7",
                scale_denominator: 4_367_830.187724359,
                matrix_width: 128,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 128,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "8",
                scale_denominator: 2_183_915.0938621797,
                matrix_width: 256,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 256,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "9",
                scale_denominator: 1_091_957.5469310898,
                matrix_width: 512,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 512,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "10",
                scale_denominator: 545_978.7734655449,
                matrix_width: 1024,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 1024,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "11",
                scale_denominator: 272_989.38673277246,
                matrix_width: 2048,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 2048,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "12",
                scale_denominator: 136_494.69336638623,
                matrix_width: 4096,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 4096,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "13",
                scale_denominator: 68_247.34668319311,
                matrix_width: 8192,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 8192,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "14",
                scale_denominator: 34_123.67334159656,
                matrix_width: 16_384,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 16_384,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "15",
                scale_denominator: 17_061.83667079828,
                matrix_width: 32_768,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 32_768,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "16",
                scale_denominator: 8530.91833539914,
                matrix_width: 65_536,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 65_536,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "17",
                scale_denominator: 4265.45916769957,
                matrix_width: 131_072,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 131_072,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "18",
                scale_denominator: 2132.729583849785,
                matrix_width: 262_144,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 262_144,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "19",
                scale_denominator: 1066.3647919248924,
                matrix_width: 524_288,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 524_288,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "20",
                scale_denominator: 533.1823959624462,
                matrix_width: 1_048_576,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 1_048_576,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "21",
                scale_denominator: 266.5911979812231,
                matrix_width: 2_097_152,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 2_097_152,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "22",
                scale_denominator: 133.29559899061155,
                matrix_width: 4_194_304,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 4_194_304,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "23",
                scale_denominator: 66.64779949530578,
                matrix_width: 8_388_608,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 8_388_608,
                tile_height: 256,
                tile_width: 256
              },
              %{
                identifier: "24",
                scale_denominator: 33.32389974765289,
                matrix_width: 16_777_216,
                top_left_corner: {-20_037_508.342789244, 20_037_508.342789244},
                matrix_height: 16_777_216,
                tile_height: 256,
                tile_width: 256
              }
            ]
          }
        ],
        formats: ["image/png", "image/jpeg"]
      } = capabilities
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
           %{
             identifier: "test_matrix",
             supported_crs: "EPSG:3857",
             matrices: [
               %{
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
         ],
         formats: ["image/png"]
       }} = CapabilitiesParser.parse(minimal_xml)
    end
  end
end
