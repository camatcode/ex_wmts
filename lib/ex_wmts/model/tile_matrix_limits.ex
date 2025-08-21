defmodule ExWMTS.TileMatrixLimits do
  @moduledoc false

  import ExWMTS.Model.Common
  import SweetXml

  alias __MODULE__, as: TileMatrixLimits

  defstruct [:tile_matrix, :min_tile_row, :max_tile_row, :min_tile_col, :max_tile_col]

  def build(nil), do: nil
  def build([]), do: nil

  def build(limits_nodes) when is_list(limits_nodes), do: Enum.map(limits_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(limits_node) do
    limits_data =
      limits_node
      |> xpath(~x".",
        tile_matrix: ~x"./*[local-name()='TileMatrix']/text()"s,
        min_tile_row: ~x"./*[local-name()='MinTileRow']/text()"s,
        max_tile_row: ~x"./*[local-name()='MaxTileRow']/text()"s,
        min_tile_col: ~x"./*[local-name()='MinTileCol']/text()"s,
        max_tile_col: ~x"./*[local-name()='MaxTileCol']/text()"s
      )

    tile_matrix = normalize_text(limits_data.tile_matrix, nil)

    if tile_matrix do
      %TileMatrixLimits{
        tile_matrix: tile_matrix,
        min_tile_row: parse_integer(limits_data.min_tile_row, 0),
        max_tile_row: parse_integer(limits_data.max_tile_row, 0),
        min_tile_col: parse_integer(limits_data.min_tile_col, 0),
        max_tile_col: parse_integer(limits_data.max_tile_col, 0)
      }
    end
  end
end
