defmodule ExWMTS.Layer do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               Layer element describing an individual layer served by a WMTS server.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4:

               "A Layer element describes an individual layer served by a WMTS server. A Layer element shall have 
               an Identifier, Title, and one or more Format elements. The server shall list for each layer all the 
               TileMatrixSet elements that can be used to request tiles from the layer."
               """,
               example: """
               %ExWMTS.Layer{
                 identifier: "MERRA2_2m_Air_Temperature_Monthly",
                 title: "2-meter Air Temperature, (Monthly, MERRA2)",
                 abstract: nil,
                 formats: ["image/png"],
                 tile_matrix_sets: ["2km"],
                 styles: ["default"],
                 keywords: [],
                 wgs84_bounding_box: %ExWMTS.WGS84BoundingBox{
                   lower_corner: {-180.0, -90.0},
                   upper_corner: {180.0, 90.0}
                 },
                 bounding_box: nil,
                 metadata: [
                   %ExWMTS.Metadata{
                     href: "https://gibs.earthdata.nasa.gov/colormaps/v1.3/MERRA2_2m_Air_Temperature_Monthly.xml",
                     about: ""
                   }
                 ],
                 dimensions: [
                   %ExWMTS.Dimension{
                     identifier: "Time",
                     title: "",
                     abstract: "",
                     units_symbol: "",
                     unit_symbol: "",
                     default: "2025-06-05",
                     current: "",
                     values: ["1980-01-01/2023-11-01/P1M", "2025-01-01/2025-04-01/P1M"]
                   }
                 ],
                 resource_urls: [
                   %ExWMTS.ResourceURL{
                     format: "image/png",
                     resource_type: "tile",
                     template: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/MERRA2_2m_Air_Temperature_Monthly/default/{Time}/{TileMatrixSet}/{TileMatrix}/{TileRow}/{TileCol}.png"
                   }
                 ],
                 tile_matrix_set_links: [
                   %ExWMTS.TileMatrixSetLink{
                     tile_matrix_set: "2km",
                     tile_matrix_set_limits: nil
                   }
                 ]
               }
               """,
               related: [ExWMTS.CapabilitiesParser, ExWMTS.WMTSClient]
             )
  import ExWMTS.Model.Common

  alias __MODULE__, as: Layer
  alias ExWMTS.{BoundingBox, Dimension, Metadata, ResourceURL, TileMatrixSetLink, WGS84BoundingBox}

  @typedoc ExWMTS.Doc.type_doc("Unique identifier for this layer", example: "\"MERRA2_2m_Air_Temperature_Monthly\"")
  @type layer_identifier :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Human-readable title for this layer",
             example: "\"2-meter Air Temperature, (Monthly, MERRA2)\""
           )
  @type title :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Brief narrative description of this layer",
             example: "\"Monthly global air temperature data from MERRA2 reanalysis\""
           )
  @type abstract :: String.t()

  @typedoc ExWMTS.Doc.type_doc("List of supported MIME types for tiles", example: ~s(["image/png", "image/jpeg"]))
  @type formats :: [String.t()]

  @typedoc ExWMTS.Doc.type_doc("List of TileMatrixSet identifiers applicable to this layer",
             example: ~s(["2km", "GoogleMapsCompatible"])
           )
  @type tile_matrix_sets :: [String.t()]

  @typedoc ExWMTS.Doc.type_doc("List of style identifiers applicable to this layer",
             example: ~s(["default", "contours"])
           )
  @type styles :: [String.t()]

  @typedoc ExWMTS.Doc.type_doc("List of descriptive keywords about the layer",
             example: ~s(["temperature", "climate", "MERRA2"])
           )
  @type keywords :: [String.t()]

  @typedoc ExWMTS.Doc.type_doc("Type describing a WMTS layer",
             keys: %{
               identifier: {Layer, :layer_identifier},
               title: Layer,
               abstract: Layer,
               formats: Layer,
               tile_matrix_sets: Layer,
               styles: Layer,
               keywords: Layer,
               wgs84_bounding_box: ExWMTS.WGS84BoundingBox,
               bounding_box: {ExWMTS.BoundingBox, :t, :list},
               metadata: {ExWMTS.Metadata, :t, :list},
               dimensions: {ExWMTS.Dimension, :t, :list},
               resource_urls: {ExWMTS.ResourceURL, :t, :list},
               tile_matrix_set_links: {ExWMTS.TileMatrixSetLink, :t, :list}
             },
             example: """
             %ExWMTS.Layer{
               identifier: "MERRA2_2m_Air_Temperature_Monthly",
               title: "2-meter Air Temperature, (Monthly, MERRA2)",
               formats: ["image/png"],
               tile_matrix_sets: ["2km"],
               styles: ["default"]
             }
             """,
             related: [ExWMTS.CapabilitiesParser, ExWMTS.WMTSClient]
           )
  @type t :: %Layer{
          identifier: layer_identifier(),
          title: title(),
          abstract: abstract(),
          formats: formats(),
          tile_matrix_sets: tile_matrix_sets(),
          styles: styles(),
          keywords: keywords(),
          wgs84_bounding_box: WGS84BoundingBox.t(),
          bounding_box: [BoundingBox.t()],
          metadata: [Metadata.t()],
          dimensions: [Dimension.t()],
          resource_urls: [ResourceURL.t()],
          tile_matrix_set_links: [TileMatrixSetLink.t()]
        }

  defstruct [
    :identifier,
    :title,
    :abstract,
    :formats,
    :tile_matrix_sets,
    :styles,
    keywords: [],
    wgs84_bounding_box: nil,
    bounding_box: [],
    metadata: [],
    dimensions: [],
    resource_urls: [],
    tile_matrix_set_links: []
  ]

  @doc ExWMTS.Doc.func_doc("Builds Layer structs from XML nodes or maps",
         params: %{layer_data: "XML node, map, list of nodes/maps, or nil to build into Layer structs"}
       )
  @spec build(nil) :: nil
  @spec build([]) :: []
  @spec build([map() | term()]) :: [Layer.t()]
  @spec build(map() | term()) :: Layer.t() | nil
  def build(nil), do: nil
  def build([]), do: nil

  def build(layer_nodes) when is_list(layer_nodes) do
    layer_nodes
    |> Enum.map(&build/1)
    |> Enum.reject(&is_nil/1)
  end

  def build(m) when is_map(m) do
    case make_layer(m) do
      nil -> nil
      layer_map -> struct(Layer, layer_map)
    end
  end

  def build(layer_node) do
    layer = make_layer(layer_node)
    if layer, do: struct(Layer, layer)
  end

  defp make_layer(layer_data) do
    identifier = normalize_text(layer_data.identifier, nil)
    title = normalize_text(layer_data.title, identifier)
    abstract = normalize_text(layer_data.abstract, nil)

    keywords = layer_data.keywords || []
    wgs84_bounding_box = WGS84BoundingBox.build(layer_data.wgs84_bounding_box)
    bounding_box = BoundingBox.build(layer_data.bounding_box)
    metadata = Metadata.build(layer_data.metadata)
    dimensions = Dimension.build(layer_data.dimensions)
    resource_urls = ResourceURL.build(layer_data.resource_urls)
    tile_matrix_set_links = TileMatrixSetLink.build(layer_data.tile_matrix_set_links || [])

    formats = layer_data.formats |> Enum.map(&normalize_text/1) |> Enum.reject(&(&1 == nil)) |> Enum.uniq()
    tile_matrix_sets = layer_data.tile_matrix_sets |> Enum.map(&normalize_text/1) |> Enum.reject(&(&1 == nil))

    styles =
      layer_data.styles
      |> Enum.map(&normalize_text/1)
      |> Enum.reject(&(&1 == nil))
      |> case do
        [] -> ["default"]
        s -> s
      end
      |> Enum.uniq()

    if identifier != nil and !Enum.empty?(formats) do
      %{
        identifier: identifier,
        title: title,
        abstract: abstract,
        keywords: keywords,
        wgs84_bounding_box: wgs84_bounding_box,
        bounding_box: bounding_box,
        metadata: metadata,
        dimensions: dimensions,
        resource_urls: resource_urls,
        tile_matrix_set_links: tile_matrix_set_links,
        formats: formats,
        tile_matrix_sets: tile_matrix_sets,
        styles: styles
      }
    end
  end
end
