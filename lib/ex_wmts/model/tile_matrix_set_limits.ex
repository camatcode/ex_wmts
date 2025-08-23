defmodule ExWMTS.TileMatrixSetLimits do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               TileMatrixSetLimits defining spatial and resolution constraints for a layer's tile access.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4.6.2:

               "The TileMatrixSetLimits element shall define the spatial and/or resolution limits of the tiles 
               and allow a server to describe a layer as having a limited spatial and/or resolution extent."
               """,
               example: """
               %ExWMTS.TileMatrixSetLimits{
                 tile_matrix_set: "GoogleMapsCompatible",
                 tile_matrix_limits: [
                   %ExWMTS.TileMatrixLimits{
                     tile_matrix: "0",
                     min_tile_row: 0,
                     max_tile_row: 0,
                     min_tile_col: 0,
                     max_tile_col: 1
                   }
                 ]
               }
               """,
               related: [ExWMTS.TileMatrixSetLink, ExWMTS.TileMatrixLimits]
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: TileMatrixSetLimits
  alias ExWMTS.TileMatrixLimits

  @typedoc ExWMTS.Doc.type_doc("Identifier of the TileMatrixSet being constrained", example: "\"GoogleMapsCompatible\"")
  @type tile_matrix_set :: String.t()

  @typedoc ExWMTS.Doc.type_doc("List of TileMatrixLimits defining spatial constraints",
             example: "[%ExWMTS.TileMatrixLimits{tile_matrix: \"0\", min_tile_row: 0, max_tile_row: 0}]"
           )
  @type tile_matrix_limits :: [TileMatrixLimits.t()]

  @typedoc ExWMTS.Doc.type_doc("Spatial and resolution limits for a TileMatrixSet",
             example:
               "%ExWMTS.TileMatrixSetLimits{tile_matrix_set: \"GoogleMapsCompatible\", tile_matrix_limits: [%ExWMTS.TileMatrixLimits{...}]}"
           )
  @type tile_matrix_set_limits :: t()

  @typedoc ExWMTS.Doc.type_doc("Type describing spatial and resolution limits for a TileMatrixSet",
             keys: %{
               tile_matrix_set: TileMatrixSetLimits,
               tile_matrix_limits: {ExWMTS.TileMatrixLimits, :t, :list}
             },
             example: """
             %ExWMTS.TileMatrixSetLimits{
               tile_matrix_set: "GoogleMapsCompatible",
               tile_matrix_limits: [%ExWMTS.TileMatrixLimits{...}]
             }
             """,
             related: [ExWMTS.TileMatrixSetLink, ExWMTS.TileMatrixLimits]
           )
  @type t :: %TileMatrixSetLimits{
          tile_matrix_set: tile_matrix_set(),
          tile_matrix_limits: [TileMatrixLimits.t()]
        }

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
