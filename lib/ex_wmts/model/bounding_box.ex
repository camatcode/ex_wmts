defmodule ExWMTS.BoundingBox do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               BoundingBox defining a minimum bounding rectangle in a specific coordinate reference system.

               From OWS Common Specification (OGC 06-121r9), Section 10.2:

               "A BoundingBox element encodes an MD bounding box (or bounding rectangle, or in 3D a 
               bounding box) used to indicate what data is available. This BoundingBox element is 
               primarily used in GetCapabilities operation responses."
               """,
               example: """
               %ExWMTS.BoundingBox{
                 crs: "urn:ogc:def:crs:EPSG::3857",
                 lower_corner: {-20037507.85759102, -30242455.261924103},
                 upper_corner: {20052492.93656824, 30240972.179360494}
               }
               """,
               related: [ExWMTS.WGS84BoundingBox, ExWMTS.Layer]
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: BoundingBox

  @typedoc ExWMTS.Doc.type_doc("Coordinate reference system identifier", example: "\"urn:ogc:def:crs:EPSG::3857\"")
  @type crs :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Lower corner coordinates as {x, y} tuple in the CRS",
             example: "{-20037507.85759102, -30242455.261924103}"
           )
  @type lower_corner :: {float(), float()}

  @typedoc ExWMTS.Doc.type_doc("Upper corner coordinates as {x, y} tuple in the CRS",
             example: "{20052492.93656824, 30240972.179360494}"
           )
  @type upper_corner :: {float(), float()}

  @typedoc ExWMTS.Doc.type_doc("Type describing a bounding box in a specific coordinate reference system",
             keys: %{
               crs: BoundingBox,
               lower_corner: BoundingBox,
               upper_corner: BoundingBox
             },
             example: """
             %ExWMTS.BoundingBox{
                crs: "urn:ogc:def:crs:EPSG::3857",
                lower_corner: {-20037507.85759102, -30242455.261924103},
                upper_corner: {20052492.93656824, 30240972.179360494}
             }
             """,
             related: [ExWMTS.WGS84BoundingBox, ExWMTS.Layer]
           )
  @type t :: %BoundingBox{
          crs: crs(),
          lower_corner: lower_corner(),
          upper_corner: upper_corner()
        }

  defstruct [:crs, :lower_corner, :upper_corner]

  @doc ExWMTS.Doc.func_doc("Builds BoundingBox struct(s) from XML node(s)",
         params: %{bbox_nodes: "XML node(s) to build into BoundingBox struct(s)"}
       )

  @spec build(map()) :: BoundingBox.t() | [BoundingBox.t()] | nil
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
