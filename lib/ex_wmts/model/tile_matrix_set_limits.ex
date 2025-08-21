defmodule ExWMTS.TileMatrixSetLimits do
  @moduledoc false

  import SweetXml

  alias __MODULE__, as: TileMatrixSetLimits
  alias ExWMTS.TileMatrixLimits

  defstruct [:tile_matrix_set, :tile_matrix_limits]

  def build(nil), do: nil

  def build(limits_node) do
    # TileMatrixSetLimits node contains only TileMatrixLimits children
    # The TileMatrixSet identifier comes from the parent TileMatrixSetLink
    tile_matrix_limits_nodes = limits_node |> xpath(~x"./*[local-name()='TileMatrixLimits']"el)

    if tile_matrix_limits_nodes != [] do
      tile_matrix_limits = TileMatrixLimits.build(tile_matrix_limits_nodes)

      %TileMatrixSetLimits{
        # Will be set by TileMatrixSetLink
        tile_matrix_set: nil,
        tile_matrix_limits: tile_matrix_limits
      }
    end
  end
end
