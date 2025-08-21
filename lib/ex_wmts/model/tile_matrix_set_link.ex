defmodule ExWMTS.TileMatrixSetLink do
  @moduledoc false

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
