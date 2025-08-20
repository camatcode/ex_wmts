defmodule ExWMTS.TileMatrix do
  @moduledoc false

  import ExWMTS.Model.Common
  import SweetXml

  alias __MODULE__, as: TileMatrix

  defstruct [
    :identifier,
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
      scale_denominator: scale_denominator,
      top_left_corner: top_left_corner,
      tile_width: tile_width,
      tile_height: tile_height,
      matrix_width: matrix_width,
      matrix_height: matrix_height
    } =
      tm_node
      |> xpath(~x".",
        identifier: ~x"./*[local-name()='Identifier']/text()"s,
        scale_denominator: ~x"./*[local-name()='ScaleDenominator']/text()"s,
        tile_width: ~x"./*[local-name()='TileWidth']/text()"s,
        tile_height: ~x"./*[local-name()='TileHeight']/text()"s,
        matrix_width: ~x"./*[local-name()='MatrixWidth']/text()"s,
        matrix_height: ~x"./*[local-name()='MatrixHeight']/text()"s,
        top_left_corner: ~x"./*[local-name()='TopLeftCorner']/text()"s
      )

    identifier = normalize_text(identifier, nil)
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
      scale_denominator: scale_denominator,
      top_left_corner: top_left_corner,
      tile_width: tile_width,
      tile_height: tile_height,
      matrix_width: matrix_width,
      matrix_height: matrix_height
    }
  end
end
