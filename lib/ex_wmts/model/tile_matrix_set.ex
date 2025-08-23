defmodule ExWMTS.TileMatrixSet do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               TileMatrixSet defining a tiling scheme for a coordinate reference system.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.3:

               "A TileMatrixSet defines a particular tiling scheme for a coordinate reference system. It contains 
               the TileMatrix definitions that define the tiling schemes for each scale and the spatial extent 
               (BoundingBox) that contains all the tiles."
               """,
               example: """
               %ExWMTS.TileMatrixSet{
                 identifier: "16km",
                 title: nil,
                 abstract: nil,
                 keywords: [],
                 supported_crs: "urn:ogc:def:crs:OGC:1.3:CRS84",
                 bounding_box: nil,
                 well_known_scale_set: nil,
                 matrices: [
                   %ExWMTS.TileMatrix{
                     identifier: "0",
                     scale_denominator: 223632905.6114871,
                     tile_width: 512,
                     tile_height: 512,
                     matrix_width: 2,
                     matrix_height: 1,
                     top_left_corner: {-180.0, 90.0}
                   },
                   %ExWMTS.TileMatrix{
                     identifier: "1", 
                     scale_denominator: 111816452.8057436,
                     tile_width: 512,
                     tile_height: 512,
                     matrix_width: 3,
                     matrix_height: 2,
                     top_left_corner: {-180.0, 90.0}
                   }
                 ]
               }
               """,
               related: [ExWMTS.TileMatrix, ExWMTS.Layer]
             )

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: TileMatrixSet
  alias ExWMTS.{BoundingBox, TileMatrix}

  @typedoc ExWMTS.Doc.type_doc("Unique identifier for this TileMatrixSet", example: "\"16km\"")
  @type tms_identifier :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Human-readable title for the TileMatrixSet",
             example: "\"16km Resolution TileMatrixSet\""
           )
  @type title :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Brief narrative description of the TileMatrixSet",
             example: "\"Global tiling scheme at 16km resolution\""
           )
  @type abstract :: String.t()

  @typedoc ExWMTS.Doc.type_doc("List of descriptive keywords", example: ~s(["global", "16km", "overview"]))
  @type keywords :: [String.t()]

  @typedoc ExWMTS.Doc.type_doc("Coordinate reference system identifier", example: "\"urn:ogc:def:crs:OGC:1.3:CRS84\"")
  @type supported_crs :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Well-known identifier for a scale set",
             example: "\"urn:ogc:def:wkss:OGC:1.0:GoogleMapsCompatible\""
           )
  @type well_known_scale_set :: String.t()

  @typedoc ExWMTS.Doc.type_doc("List of TileMatrix elements defining the tiling scheme at different scales",
             example: ~s([%ExWMTS.TileMatrix{identifier: "0"}, %ExWMTS.TileMatrix{identifier: "1"}])
           )
  @type matrices :: [TileMatrix.t()]

  @typedoc ExWMTS.Doc.type_doc("Type describing a tiling scheme for a coordinate reference system",
             keys: %{
               identifier: {TileMatrixSet, :tms_identifier},
               title: TileMatrixSet,
               abstract: TileMatrixSet,
               keywords: TileMatrixSet,
               supported_crs: TileMatrixSet,
               bounding_box: {ExWMTS.BoundingBox, :t},
               well_known_scale_set: TileMatrixSet,
               matrices: {ExWMTS.TileMatrix, :t, :list}
             },
             example: """
             %ExWMTS.TileMatrixSet{
               identifier: "16km",
               supported_crs: "urn:ogc:def:crs:OGC:1.3:CRS84",
               matrices: [
                 %ExWMTS.TileMatrix{identifier: "0", scale_denominator: 223632905.6114871}
               ]
             }
             """,
             related: [ExWMTS.TileMatrix, ExWMTS.Layer]
           )
  @type t :: %TileMatrixSet{
          identifier: tms_identifier(),
          title: title(),
          abstract: abstract(),
          keywords: keywords(),
          supported_crs: supported_crs(),
          bounding_box: BoundingBox.t(),
          well_known_scale_set: well_known_scale_set(),
          matrices: matrices()
        }

  defstruct [:identifier, :title, :abstract, :keywords, :supported_crs, :bounding_box, :well_known_scale_set, :matrices]

  @doc ExWMTS.Doc.func_doc("Builds TileMatrixSet structs from XML nodes or maps",
         params: %{tms_data: "XML node, map, list of nodes/maps, or nil to build into TileMatrixSet structs"}
       )
  @spec build(nil) :: nil
  @spec build([]) :: []
  @spec build([map() | term()]) :: [TileMatrixSet.t()]
  @spec build(map() | term()) :: TileMatrixSet.t() | nil
  def build(nil), do: nil

  def build([]), do: nil

  def build(tms_nodes) when is_list(tms_nodes) do
    tms_nodes
    |> Enum.map(&build/1)
    |> Enum.reject(&is_nil/1)
  end

  def build(tms_node) do
    set = make_tile_matrix_set(tms_node)
    if set, do: struct(TileMatrixSet, set)
  end

  defp make_tile_matrix_set(tms_node) do
    tms_data =
      tms_node
      |> xpath(~x".",
        identifier: text("Identifier"),
        title: text("Title"),
        abstract: text("Abstract"),
        keywords: ~x"./*[local-name()='Keywords']/*[local-name()='Keyword']/text()"sl,
        supported_crs: text("SupportedCRS"),
        bounding_box: element("BoundingBox"),
        well_known_scale_set: text("WellKnownScaleSet"),
        matrices: element_list("TileMatrix")
      )

    identifier = normalize_text(tms_data.identifier, nil)

    if identifier do
      title = normalize_text(tms_data.title, nil)
      abstract = normalize_text(tms_data.abstract, nil)
      keywords = tms_data.keywords |> Enum.map(&normalize_text(&1, nil)) |> Enum.reject(&is_nil/1)
      supported_crs = normalize_text(tms_data.supported_crs, "EPSG:4326")
      bounding_box = BoundingBox.build(tms_data.bounding_box)
      well_known_scale_set = normalize_text(tms_data.well_known_scale_set, nil)

      matrices =
        tms_data.matrices
        |> Enum.map(&ExWMTS.TileMatrix.build/1)
        |> Enum.reject(&(&1 == nil or &1.identifier == nil))

      %{
        identifier: identifier,
        title: title,
        abstract: abstract,
        keywords: keywords,
        supported_crs: supported_crs,
        bounding_box: bounding_box,
        well_known_scale_set: well_known_scale_set,
        matrices: matrices
      }
    end
  end
end
