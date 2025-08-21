defmodule ExWMTS.TileMatrix do
  @moduledoc """
  TileMatrix defining how space is partitioned into a set of square tiles at a particular scale.

  From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.3.2:

  "A TileMatrix defines how space is partitioned into a set of square tiles. The TileMatrix defines 
  a particular tile matrix by defining its limits (MatrixWidth, MatrixHeight), the tile size 
  (TileWidth, TileHeight) and geospatial metadata."

  ## Required Elements

  - `identifier` - Unique identifier for this matrix within the TileMatrixSet
  - `scale_denominator` - Scale denominator level of this tile matrix  
  - `top_left_corner` - Position in CRS coordinates of the top-left corner of this tile matrix
  - `tile_width` - Width of each tile in pixels
  - `tile_height` - Height of each tile in pixels
  - `matrix_width` - Number of tiles in the horizontal direction (columns)
  - `matrix_height` - Number of tiles in the vertical direction (rows)

  ## Optional Elements

  - `title` - Human-readable title for the matrix
  - `abstract` - Brief narrative description of the matrix
  - `keywords` - List of descriptive keywords

  From Section 7.2.3.2.1: "The ScaleDenominator element shall contain the scale denominator of the 
  tile matrix. The scale denominator is defined with respect to a 'standardized rendering pixel size' 
  of 0.28 mm × 0.28 mm (millimeters)."

  From Section 7.2.3.2.2: "The TopLeftCorner element shall contain the position in CRS coordinates 
  of the top-left corner of this tile matrix. This corner is also a corner of the (0, 0) tile."

  From Section 7.2.3.2.3: "The TileWidth and TileHeight elements shall contain the width and height 
  of each tile in pixels. All tiles in the matrix shall have the same pixel size."
  """

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: TileMatrix

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
