defmodule ExWMTS.WGS84BoundingBox do
  @moduledoc """
  WGS84BoundingBox defining a minimum bounding rectangle in WGS84 longitude-latitude coordinates.

  From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4.2:

  "The WGS84BoundingBox element shall identify the minimum bounding rectangle in WGS84 
  longitude-latitude that encloses the area applicable to the layer."

  ## Required Elements

  - `lower_corner` - Lower corner coordinates as {longitude, latitude} tuple
  - `upper_corner` - Upper corner coordinates as {longitude, latitude} tuple

  From OWS Common Specification (OGC 06-121r9), Section 10.2:

  "A BoundingBox element encodes an MD bounding box (or bounding rectangle, or in 3D a 
  bounding box) used to indicate what data is available. This BoundingBox element is 
  primarily used in GetCapabilities operation responses."

  ## Coordinate Order

  For WGS84BoundingBox, coordinates are specified as:
  - Lower corner: {minimum_longitude, minimum_latitude}  
  - Upper corner: {maximum_longitude, maximum_latitude}

  Values are in decimal degrees with longitude in range [-180, 180] and 
  latitude in range [-90, 90].

  ## Usage

  This bounding box provides a quick spatial reference for:
  - Layer discovery and filtering
  - Determining data availability  
  - Client-side spatial indexing
  - Geographic extent validation
  """

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
