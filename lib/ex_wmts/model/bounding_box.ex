defmodule ExWMTS.BoundingBox do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               A struct defining a minimum bounding rectangle surrounding dataset, in available CRS
               """,
               example: """
               %ExWMTS.BoundingBox{
                 crs: "urn:ogc:def:crs:EPSG::3857",
                 lower_corner: {-20037507.85759102, -30242455.261924103},
                 upper_corner: {20052492.93656824, 30240972.179360494},
                 dimensions: 2
               }
               """,
               related: [ExWMTS.WGS84BoundingBox, ExWMTS.Layer]
             )

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: BoundingBox

  @typedoc ExWMTS.Doc.type_doc("Reference to definition of the CRS used by the LowerCorner and UpperCorner coordinates",
             example: "\"urn:ogc:def:crs:EPSG::3857\""
           )
  @type crs :: String.t()

  @typedoc ExWMTS.Doc.type_doc("The number of dimensions in this CRS (the length of a coordinate sequence)",
             example: "2"
           )
  @type dimensions :: pos_integer()

  @typedoc ExWMTS.Doc.type_doc(
             "Coordinates of bounding box corner at which the value of each coordinate normally is the algebraic minimum within this bounding box",
             example: "{-20037507.85759102, -30242455.261924103}"
           )
  @type lower_corner :: {float(), float()}

  @typedoc ExWMTS.Doc.type_doc(
             "Coordinates of bounding box corner at which the value of each coordinate normally is the algebraic maximum within this bounding box",
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
                upper_corner: {20052492.93656824, 30240972.179360494},
                dimensions: 2
             }
             """,
             related: [ExWMTS.WGS84BoundingBox, ExWMTS.Layer]
           )
  @type t :: %BoundingBox{
          crs: crs(),
          lower_corner: lower_corner(),
          upper_corner: upper_corner(),
          dimensions: dimensions()
        }

  defstruct [:crs, :lower_corner, :upper_corner, :dimensions]

  @doc ExWMTS.Doc.func_doc("Builds BoundingBox struct(s) from XML node(s)",
         params: %{bbox_data: "XML node(s) to build into BoundingBox struct(s)"}
       )
  @spec build(map()) :: BoundingBox.t() | [BoundingBox.t()] | nil
  def build(nil), do: nil
  def build([]), do: nil
  def build(bbox_data) when is_list(bbox_data), do: Enum.map(bbox_data, &build/1) |> Enum.reject(&is_nil/1)

  def build(bbox_data) do
    crs = bbox_data |> xpath(attribute("crs"))
    dimensions = bbox_data |> xpath(attribute("dimensions")) |> parse_integer(2)
    lower = bbox_data |> xpath(text("LowerCorner")) |> parse_coords(dimensions)
    upper = bbox_data |> xpath(text("UpperCorner")) |> parse_coords(dimensions)

    %BoundingBox{crs: crs, lower_corner: lower, upper_corner: upper, dimensions: dimensions}
  end

  defp parse_coords(coord_string, dimensions) when is_binary(coord_string) do
    coords = String.split(coord_string) |> Enum.take(dimensions)

    case length(coords) do
      ^dimensions -> coords |> parse_coordinate_values() |> List.to_tuple()
      _ -> nil
    end
  end

  defp parse_coords(_, _), do: nil

  defp parse_coordinate_values(coords) do
    coords
    |> Enum.map(&parse_single_coordinate/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_single_coordinate(str_coord) do
    case Float.parse(str_coord) do
      {coord, ""} -> coord
      _ -> nil
    end
  end
end
