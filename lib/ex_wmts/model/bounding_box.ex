defmodule ExWMTS.BoundingBox do
  @moduledoc false

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: BoundingBox

  defstruct [:crs, :lower_corner, :upper_corner]

  def build(nil), do: nil
  def build([]), do: nil
  def build(bbox_nodes) when is_list(bbox_nodes), do: Enum.map(bbox_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(bbox_node) do
    crs = bbox_node |> xpath(attribute("crs"))
    lower = bbox_node |> xpath(text("LowerCorner")) |> parse_coords()
    upper = bbox_node |> xpath(text("UpperCorner")) |> parse_coords()

    case {lower, upper} do
      {{min_x, min_y}, {max_x, max_y}} ->
        %BoundingBox{crs: crs, lower_corner: {min_x, min_y}, upper_corner: {max_x, max_y}}

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
