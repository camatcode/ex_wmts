defmodule ExWMTS.WGS84BoundingBox do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               WGS84BoundingBox defining a minimum bounding rectangle in WGS84 longitude-latitude coordinates.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4.2:

               "The WGS84BoundingBox element shall identify the minimum bounding rectangle in WGS84 
               longitude-latitude that encloses the area applicable to the layer."
               """,
               example: """
               %ExWMTS.WGS84BoundingBox{
                 lower_corner: {-180.0, -90.0},
                 upper_corner: {180.0, 90.0}
               }
               """,
               related: [ExWMTS.Layer, ExWMTS.BoundingBox]
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: WGS84BoundingBox

  @typedoc ExWMTS.Doc.type_doc("Lower corner coordinates as {longitude, latitude} tuple in decimal degrees",
             example: "{-180.0, -90.0}"
           )
  @type lower_corner :: {float(), float()}

  @typedoc ExWMTS.Doc.type_doc("Upper corner coordinates as {longitude, latitude} tuple in decimal degrees",
             example: "{180.0, 90.0}"
           )
  @type upper_corner :: {float(), float()}

  @typedoc ExWMTS.Doc.type_doc("WGS84 geographic bounding box",
             example: "%ExWMTS.WGS84BoundingBox{lower_corner: {-180.0, -90.0}, upper_corner: {180.0, 90.0}}"
           )
  @type wgs84_bounding_box :: t()

  @typedoc ExWMTS.Doc.type_doc("Type describing a WGS84 geographic bounding box",
             keys: %{
               lower_corner: WGS84BoundingBox,
               upper_corner: WGS84BoundingBox
             },
             example: """
             %ExWMTS.WGS84BoundingBox{
               lower_corner: {-180.0, -90.0},
               upper_corner: {180.0, 90.0}
             }
             """,
             related: [ExWMTS.Layer, ExWMTS.BoundingBox]
           )
  @type t :: %WGS84BoundingBox{
          lower_corner: lower_corner(),
          upper_corner: upper_corner()
        }

  defstruct [:lower_corner, :upper_corner]

  @doc ExWMTS.Doc.func_doc("Builds WGS84BoundingBox struct from XML node or map",
         params: %{bbox_data: "XML node, map, list of nodes/maps, or nil to build into WGS84BoundingBox struct"}
       )
  @spec build(nil) :: nil
  @spec build([]) :: nil
  @spec build(map() | term()) :: WGS84BoundingBox.t() | nil
  def build(nil), do: nil
  def build([]), do: nil

  def build(bbox_node) do
    lower = bbox_node |> xpath(text("LowerCorner")) |> parse_coords()
    upper = bbox_node |> xpath(text("UpperCorner")) |> parse_coords()

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
