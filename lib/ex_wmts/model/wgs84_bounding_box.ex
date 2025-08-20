defmodule ExWMTS.WGS84BoundingBox do
  @moduledoc false

  import SweetXml

  alias __MODULE__, as: WGS84BoundingBox

  defstruct [:lower_corner, :upper_corner]

  def build(nil), do: nil
  def build([]), do: nil

  def build(bbox_node) do
    lower = bbox_node |> xpath(~x"./*[local-name()='LowerCorner']/text()"s) |> parse_coords()
    upper = bbox_node |> xpath(~x"./*[local-name()='UpperCorner']/text()"s) |> parse_coords()

    case {lower, upper} do
      {{min_x, min_y}, {max_x, max_y}} -> %WGS84BoundingBox{lower_corner: {min_x, min_y}, upper_corner: {max_x, max_y}}
      _ -> nil
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
