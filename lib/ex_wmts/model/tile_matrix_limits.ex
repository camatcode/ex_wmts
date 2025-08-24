defmodule ExWMTS.TileMatrixLimits do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               TileMatrixLimits defining the spatial extent of available tiles for one TileMatrix.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4.6.2.1:

               "Each TileMatrixLimits element shall define the spatial limits of the tiles for one 
               TileMatrix in a TileMatrixSet. The TileMatrixLimits element identifies the TileMatrix 
               and contains the MinTileRow, MaxTileRow, MinTileCol, and MaxTileCol values."

               ## Required Elements

               - `tile_matrix` - Identifier of the TileMatrix being constrained
               - `min_tile_row` - Minimum row index of available tiles
               - `max_tile_row` - Maximum row index of available tiles  
               - `min_tile_col` - Minimum column index of available tiles
               - `max_tile_col` - Maximum column index of available tiles

               ## Tile Index Ranges

               From the standard:
               - Row indices increase from north to south (top to bottom)
               - Column indices increase from west to east (left to right)
               - Indices are zero-based (first tile is at row=0, col=0)
               - Ranges are inclusive (both min and max values are available)

               ## Geographic Interpretation

               These limits define a rectangular extent in tile space:
               - (min_tile_col, min_tile_row) = Top-left corner tile
               - (max_tile_col, max_tile_row) = Bottom-right corner tile

               ## Usage Examples

               For France at zoom level 11: rows 681-772, columns 989-1087
               For continental US at zoom level 8: rows 45-120, columns 25-75

               This enables clients to validate tile requests and implement 
               efficient tile loading strategies within known data bounds.
               """,
               example: """
               %ExWMTS.TileMatrixLimits{
                 tile_matrix: "11",
                 min_tile_row: 681,
                 max_tile_row: 772,
                 min_tile_col: 989,
                 max_tile_col: 1087
               }
               """,
               related: [ExWMTS.TileMatrixSetLimits, ExWMTS.TileMatrix]
             )

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: TileMatrixLimits

  @typedoc ExWMTS.Doc.type_doc("Identifier of the TileMatrix being constrained", example: "\"11\"")
  @type tile_matrix :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Minimum row index of available tiles", example: "681")
  @type min_tile_row :: non_neg_integer()

  @typedoc ExWMTS.Doc.type_doc("Maximum row index of available tiles", example: "772")
  @type max_tile_row :: non_neg_integer()

  @typedoc ExWMTS.Doc.type_doc("Minimum column index of available tiles", example: "989")
  @type min_tile_col :: non_neg_integer()

  @typedoc ExWMTS.Doc.type_doc("Maximum column index of available tiles", example: "1087")
  @type max_tile_col :: non_neg_integer()

  @typedoc ExWMTS.Doc.type_doc("Type describing spatial limits of tiles for one TileMatrix",
             keys: %{
               tile_matrix: TileMatrixLimits,
               min_tile_row: TileMatrixLimits,
               max_tile_row: TileMatrixLimits,
               min_tile_col: TileMatrixLimits,
               max_tile_col: TileMatrixLimits
             },
             example: """
             %ExWMTS.TileMatrixLimits{
               tile_matrix: "11",
               min_tile_row: 681,
               max_tile_row: 772,
               min_tile_col: 989,
               max_tile_col: 1087
             }
             """,
             related: [ExWMTS.TileMatrixSetLimits, ExWMTS.TileMatrix]
           )
  @type t :: %TileMatrixLimits{
          tile_matrix: tile_matrix(),
          min_tile_row: min_tile_row(),
          max_tile_row: max_tile_row(),
          min_tile_col: min_tile_col(),
          max_tile_col: max_tile_col()
        }

  defstruct [:tile_matrix, :min_tile_row, :max_tile_row, :min_tile_col, :max_tile_col]

  @doc ExWMTS.Doc.func_doc("Builds TileMatrixLimits structs from XML nodes or maps",
         params: %{limits_data: "XML node, map, list of nodes/maps, or nil to build into TileMatrixLimits structs"}
       )
  @spec build(nil) :: nil
  @spec build([]) :: []
  @spec build([map() | term()]) :: [TileMatrixLimits.t()]
  @spec build(map() | term()) :: TileMatrixLimits.t() | nil
  def build(nil), do: nil
  def build([]), do: nil

  def build(limits_nodes) when is_list(limits_nodes), do: Enum.map(limits_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(limits_node) do
    limits_data =
      limits_node
      |> xpath(~x".",
        tile_matrix: text("TileMatrix"),
        min_tile_row: text("MinTileRow"),
        max_tile_row: text("MaxTileRow"),
        min_tile_col: text("MinTileCol"),
        max_tile_col: text("MaxTileCol")
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
