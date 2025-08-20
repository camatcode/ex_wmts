defmodule ExWMTS.TileMatrixSet do
  @moduledoc false

  import ExWMTS.Model.Common

  alias __MODULE__, as: TileMatrixSet

  defstruct [:identifier, :supported_crs, :matrices]

  def build(nil), do: nil

  def build(tms_node) do
    set = make_tile_matrix_set(tms_node)
    if set, do: struct(TileMatrixSet, set)
  end

  defp make_tile_matrix_set(tms_data) do
    identifier = normalize_text(tms_data.identifier, nil)

    if identifier do
      matrices =
        tms_data.matrices
        |> Enum.map(&ExWMTS.TileMatrix.build/1)
        |> Enum.reject(&(&1 == nil or &1.identifier == nil))

      %{
        identifier: identifier,
        supported_crs: normalize_text(tms_data.supported_crs, "EPSG:4326"),
        matrices: matrices
      }
    end
  end
end
