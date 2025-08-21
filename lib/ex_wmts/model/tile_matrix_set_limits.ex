defmodule ExWMTS.TileMatrixSetLimits do
  @moduledoc """
  TileMatrixSetLimits defining spatial and resolution constraints for a layer's tile access.

  From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4.6.2:

  "The TileMatrixSetLimits element shall define the spatial and/or resolution limits of the tiles 
  and allow a server to describe a layer as having a limited spatial and/or resolution extent. 
  If this element is not present, there are no limits on the tile matrix indices except those 
  imposed by the tile matrix definition."

  ## Required Elements

  - `tile_matrix_set` - Identifier of the TileMatrixSet being constrained
  - `tile_matrix_limits` - List of TileMatrixLimits for individual matrices

  ## Purpose

  TileMatrixSetLimits enable:
  - Geographic extent restrictions (e.g., tiles only for France)
  - Resolution level limitations (e.g., only zoom levels 0-15)
  - Performance optimization by advertising available tile ranges
  - Client-side tile request validation

  ## Geographic Constraints

  From Section 7.2.4.6.2.1: "Each TileMatrixLimits element shall define the spatial limits 
  of the tiles for one TileMatrix in a TileMatrixSet."

  This allows layers to advertise:
  - Minimum and maximum tile row/column indices
  - Available zoom levels for the geographic extent
  - Sparse tile coverage patterns

  These limits help clients avoid requesting non-existent tiles and enable 
  efficient tile pre-fetching and caching strategies.
  """

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: TileMatrixSetLimits
  alias ExWMTS.TileMatrixLimits

  defstruct [:tile_matrix_set, :tile_matrix_limits]

  def build(nil), do: nil

  def build(limits_node) do
    # TileMatrixSetLimits node contains only TileMatrixLimits children
    # The TileMatrixSet identifier comes from the parent TileMatrixSetLink
    tile_matrix_limits_nodes = limits_node |> xpath(element_list("TileMatrixLimits"))

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
