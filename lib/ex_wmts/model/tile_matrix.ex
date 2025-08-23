defmodule ExWMTS.TileMatrix do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               TileMatrix defining how space is partitioned into a set of square tiles at a particular scale.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.3.2:

               "A TileMatrix defines how space is partitioned into a set of square tiles. The TileMatrix defines 
               a particular tile matrix by defining its limits (MatrixWidth, MatrixHeight), the tile size 
               (TileWidth, TileHeight) and geospatial metadata."
               """,
               example: """
               %ExWMTS.TileMatrix{
                 identifier: "0",
                 title: nil,
                 abstract: nil,
                 keywords: [],
                 scale_denominator: 223632905.6114871,
                 tile_width: 512,
                 tile_height: 512,
                 matrix_width: 2,
                 matrix_height: 1,
                 top_left_corner: {-180.0, 90.0}
               }
               """,
               related: [ExWMTS.TileMatrixSet, ExWMTS.Layer]
             )

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: TileMatrix

  @typedoc ExWMTS.Doc.type_doc("Unique identifier for this matrix within the TileMatrixSet", example: "\"0\"")
  @type matrix_identifier :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Human-readable title for the matrix", example: "\"Level 0 - Global Overview\"")
  @type title :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Brief narrative description of the matrix",
             example: "\"Global overview level with 2x1 tiles\""
           )
  @type abstract :: String.t()

  @typedoc ExWMTS.Doc.type_doc("List of descriptive keywords", example: ~s(["global", "overview"]))
  @type keywords :: [String.t()]

  @typedoc ExWMTS.Doc.type_doc("Scale denominator defined with respect to standardized rendering pixel size of 0.28mm",
             example: "223632905.6114871"
           )
  @type scale_denominator :: float()

  @typedoc ExWMTS.Doc.type_doc("Width of each tile in pixels", example: "512")
  @type tile_width :: non_neg_integer()

  @typedoc ExWMTS.Doc.type_doc("Height of each tile in pixels", example: "512")
  @type tile_height :: non_neg_integer()

  @typedoc ExWMTS.Doc.type_doc("Number of tiles in the horizontal direction (columns)", example: "2")
  @type matrix_width :: pos_integer()

  @typedoc ExWMTS.Doc.type_doc("Number of tiles in the vertical direction (rows)", example: "1")
  @type matrix_height :: pos_integer()

  @typedoc ExWMTS.Doc.type_doc("Position in CRS coordinates of the top-left corner", example: "{-180.0, 90.0}")
  @type top_left_corner :: {float(), float()}

  @typedoc ExWMTS.Doc.type_doc("Type describing a tile matrix within a TileMatrixSet",
             keys: %{
               identifier: {TileMatrix, :matrix_identifier},
               title: TileMatrix,
               abstract: TileMatrix,
               keywords: TileMatrix,
               scale_denominator: TileMatrix,
               tile_width: TileMatrix,
               tile_height: TileMatrix,
               matrix_width: TileMatrix,
               matrix_height: TileMatrix,
               top_left_corner: TileMatrix
             },
             example: """
             %ExWMTS.TileMatrix{
               identifier: "0",
               scale_denominator: 223632905.6114871,
               tile_width: 512,
               tile_height: 512,
               matrix_width: 2,
               matrix_height: 1,
               top_left_corner: {-180.0, 90.0}
             }
             """,
             related: [ExWMTS.TileMatrixSet, ExWMTS.Layer]
           )
  @type t :: %TileMatrix{
          identifier: matrix_identifier(),
          title: title(),
          abstract: abstract(),
          keywords: keywords(),
          scale_denominator: scale_denominator(),
          tile_width: tile_width(),
          tile_height: tile_height(),
          matrix_width: matrix_width(),
          matrix_height: matrix_height(),
          top_left_corner: top_left_corner()
        }

  defstruct [
    :identifier,
    :title,
    :abstract,
    :keywords,
    :scale_denominator,
    :tile_width,
    :tile_height,
    :matrix_width,
    :matrix_height,
    :top_left_corner
  ]

  @doc ExWMTS.Doc.func_doc("Builds TileMatrix struct from XML node or map",
         params: %{matrix_data: "XML node, map, or nil to build into TileMatrix struct"}
       )
  @spec build(nil) :: nil
  @spec build(map() | term()) :: TileMatrix.t() | nil
  def build(nil), do: nil

  def build(tm_node) do
    matrix = make_tile_matrix(tm_node)
    if matrix, do: struct(TileMatrix, matrix)
  end

  defp make_tile_matrix(tm_node) do
    %{
      identifier: identifier,
      title: title,
      abstract: abstract,
      keywords: keywords,
      scale_denominator: scale_denominator,
      top_left_corner: top_left_corner,
      tile_width: tile_width,
      tile_height: tile_height,
      matrix_width: matrix_width,
      matrix_height: matrix_height
    } =
      tm_node
      |> xpath(~x".",
        identifier: text("Identifier"),
        title: text("Title"),
        abstract: text("Abstract"),
        keywords: ~x"./*[local-name()='Keywords']/*[local-name()='Keyword']/text()"sl,
        scale_denominator: text("ScaleDenominator"),
        tile_width: text("TileWidth"),
        tile_height: text("TileHeight"),
        matrix_width: text("MatrixWidth"),
        matrix_height: text("MatrixHeight"),
        top_left_corner: text("TopLeftCorner")
      )

    identifier = normalize_text(identifier, nil)
    title = normalize_text(title, nil)
    abstract = normalize_text(abstract, nil)
    keywords = keywords |> Enum.map(&normalize_text(&1, nil)) |> Enum.reject(&is_nil/1)
    scale_denominator = parse_float(scale_denominator)
    tile_width = parse_integer(tile_width, 256)
    tile_height = parse_integer(tile_height, 256)
    matrix_width = parse_integer(matrix_width, 1)
    matrix_height = parse_integer(matrix_height, 1)

    top_left_corner =
      (top_left_corner || "0 0")
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
      title: title,
      abstract: abstract,
      keywords: keywords,
      scale_denominator: scale_denominator,
      top_left_corner: top_left_corner,
      tile_width: tile_width,
      tile_height: tile_height,
      matrix_width: matrix_width,
      matrix_height: matrix_height
    }
  end
end
