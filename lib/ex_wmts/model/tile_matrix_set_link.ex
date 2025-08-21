defmodule ExWMTS.TileMatrixSetLink do
  @moduledoc """
  TileMatrixSetLink connecting a layer to a specific TileMatrixSet with optional limits.

  From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4.6:

  "A TileMatrixSetLink element identifies a TileMatrixSet and optionally identifies a subset 
  of the tile matrices using a TileMatrixSetLimits element."

  ## Required Elements

  - `tile_matrix_set` - Reference to an available TileMatrixSet identifier

  ## Optional Elements  

  - `tile_matrix_set_limits` - Limits restricting the available tile matrices

  From Section 7.2.4.6.1: "The TileMatrixSet element shall contain the identifier of a 
  TileMatrixSet offered by the server."

  From Section 7.2.4.6.2: "The TileMatrixSetLimits element shall define the spatial and/or 
  resolution limits of the tiles and allow a server to describe a layer as having a limited 
  spatial and/or resolution extent. If this element is not present, there are no limits on 
  the tile matrix indices except those imposed by the tile matrix definition."

  ## Usage

  This element allows layers to:
  - Reference which TileMatrixSets can be used for tile requests
  - Optionally constrain the available tiles within those sets
  - Define geographic or zoom level boundaries for efficient tile access
  """

  import ExWMTS.Model.Common
  import SweetXml

  alias __MODULE__, as: TileMatrixSetLink
  alias ExWMTS.TileMatrixSetLimits

  defstruct [:tile_matrix_set, :tile_matrix_set_limits]

  def build(nil), do: nil
  def build([]), do: nil

  def build(link_nodes) when is_list(link_nodes), do: Enum.map(link_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(link_node) do
    link_data =
      link_node
      |> xpath(~x".",
        tile_matrix_set: ~x"./*[local-name()='TileMatrixSet']/text()"s,
        tile_matrix_set_limits: ~x"./*[local-name()='TileMatrixSetLimits']"e
      )

    tile_matrix_set = normalize_text(link_data.tile_matrix_set, nil)

    if tile_matrix_set do
      tile_matrix_set_limits =
        case TileMatrixSetLimits.build(link_data.tile_matrix_set_limits) do
          nil -> nil
          limits -> %{limits | tile_matrix_set: tile_matrix_set}
        end

      %TileMatrixSetLink{
        tile_matrix_set: tile_matrix_set,
        tile_matrix_set_limits: tile_matrix_set_limits
      }
    end
  end
end
