defmodule ExWMTS.TileMatrixSetLink do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               TileMatrixSetLink connecting a layer to a specific TileMatrixSet with optional limits.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4.6:

               "A TileMatrixSetLink element identifies a TileMatrixSet and optionally identifies a subset 
               of the tile matrices using a TileMatrixSetLimits element."
               """,
               example: """
               %ExWMTS.TileMatrixSetLink{
                 tile_matrix_set: "2km",
                 tile_matrix_set_limits: nil
               }
               """,
               related: [ExWMTS.Layer, ExWMTS.TileMatrixSet, ExWMTS.TileMatrixSetLimits]
             )

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: TileMatrixSetLink
  alias ExWMTS.TileMatrixSetLimits

  @typedoc ExWMTS.Doc.type_doc("Reference to an available TileMatrixSet identifier", example: "\"2km\"")
  @type tile_matrix_set :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Type describing a link from a layer to a TileMatrixSet",
             keys: %{
               tile_matrix_set: TileMatrixSetLink,
               tile_matrix_set_limits: ExWMTS.TileMatrixSetLimits
             },
             example: """
             %ExWMTS.TileMatrixSetLink{
               tile_matrix_set: "2km",
               tile_matrix_set_limits: nil
             }
             """,
             related: [ExWMTS.Layer, ExWMTS.TileMatrixSet, ExWMTS.TileMatrixSetLimits]
           )
  @type t :: %TileMatrixSetLink{
          tile_matrix_set: tile_matrix_set(),
          tile_matrix_set_limits: TileMatrixSetLimits.t()
        }

  defstruct [:tile_matrix_set, :tile_matrix_set_limits]

  @doc ExWMTS.Doc.func_doc("Builds TileMatrixSetLink structs from XML nodes or maps",
         params: %{link_data: "XML node, map, list of nodes/maps, or nil to build into TileMatrixSetLink structs"}
       )
  @spec build(nil) :: nil
  @spec build([]) :: []
  @spec build([map() | term()]) :: [TileMatrixSetLink.t()]
  @spec build(map() | term()) :: TileMatrixSetLink.t() | nil
  def build(nil), do: nil
  def build([]), do: nil

  def build(link_nodes) when is_list(link_nodes), do: Enum.map(link_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(link_node) do
    link_data =
      link_node
      |> xpath(~x".",
        tile_matrix_set: text("TileMatrixSet"),
        tile_matrix_set_limits: element("TileMatrixSetLimits")
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
