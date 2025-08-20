defmodule ExWMTS.BoundingBox do
  @moduledoc false

  import SweetXml

  defstruct [:crs, :lower_corner, :upper_corner]

  def build(nil), do: []
  def build([]), do: []
  def build(bbox_nodes) when is_list(bbox_nodes), do: Enum.map(bbox_nodes, &build_single/1) |> Enum.reject(&is_nil/1)

  def build(bbox_node),
    do:
      case(build_single(bbox_node),
        do: (
          nil -> []
          bbox -> [bbox]
        )
      )

  defp build_single(bbox_node) do
    crs = bbox_node |> xpath(~x"./@crs"s)
    lower = bbox_node |> xpath(~x"./*[local-name()='LowerCorner']/text()"s) |> parse_coords()
    upper = bbox_node |> xpath(~x"./*[local-name()='UpperCorner']/text()"s) |> parse_coords()

    case {lower, upper} do
      {{min_x, min_y}, {max_x, max_y}} ->
        %__MODULE__{crs: crs, lower_corner: {min_x, min_y}, upper_corner: {max_x, max_y}}

      _ ->
        nil
    end
  end

  defp parse_coords(coord_string) when is_binary(coord_string) do
    case String.split(coord_string) do
      [x_str, y_str] ->
        case {Float.parse(x_str), Float.parse(y_str)} do
          {{x, ""}, {y, ""}} -> {x, y}
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp parse_coords(_), do: nil
end
