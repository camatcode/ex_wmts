defmodule ExWMTS.CapabilitiesParserTest do
  use ExUnit.Case

  alias ExWMTS.CapabilitiesParser

  @moduletag :parser

  describe "Capabilities parser with diverse XML samples" do
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
        formats: formats
      } = capabilities

      assert "default028mm" in matrix_sets
      assert "GoogleMapsCompatible" in matrix_sets
      assert "image/jpeg" in formats and "image/png" in formats

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

      known_layer = %{
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
        service_identification: %{
          title: "OSM_WMTS_Server",
          abstract: "WMTS-based access to Open Street Map data",
          service_type: "WMTS"
        },
        layers: [
          %{
            title: "OSM_BASEMAP",
            abstract: nil,
            identifier: "OSM_BASEMAP",
            tile_matrix_sets: [
              "GlobalCRS84Scale",
              "NRLTileScheme",
              "NRLTileScheme256",
              "GlobalCRS84Pixel",
              "GoogleCRS84Quad",
              "GoogleMapsCompatible",
              "EPSG3395TiledMercator"
            ],
            formats: ["image/png", "image/jpeg"],
            styles: ["default"]
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
         service_identification: %{
           title: "Test Service",
           abstract: nil,
           service_type: "OGC WMTS",
           service_type_version: "1.0.0"
         },
         layers: [
           %{
             title: "Test Layer",
             abstract: nil,
             identifier: "test_layer",
             tile_matrix_sets: ["test_matrix"],
             formats: ["image/png"],
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
