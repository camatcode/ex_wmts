defmodule ExWMTS.ResourceURL do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               ResourceURL element providing template URLs for accessing tiles and resources.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4.5:

               "A ResourceURL element identifies a URL template to be used for accessing resources. 
               A ResourceURL element may be used to provide alternative access methods for layers."

               This enables RESTful tile access without KVP parameter encoding. Template URLs contain 
               placeholder variables that are substituted at request time.
               """,
               example: """
               %ExWMTS.ResourceURL{
                 format: "image/png",
                 resource_type: "tile",
                 template: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/MERRA2_2m_Air_Temperature_Monthly/default/{Time}/{TileMatrixSet}/{TileMatrix}/{TileRow}/{TileCol}.png"
               }
               """,
               related: [ExWMTS.Layer, ExWMTS.WMTSClient]
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: ResourceURL

  @typedoc ExWMTS.Doc.type_doc("MIME type of the resource", example: "\"image/png\"")
  @type format :: String.t()

  @typedoc ExWMTS.Doc.type_doc(~s(Type of resource, typically \\"tile\\" or \\"FeatureInfo\\"), example: "\"tile\"")
  @type resource_type :: String.t()

  @typedoc ExWMTS.Doc.type_doc(
             "URL template with placeholder variables like {TileMatrixSet}, {TileMatrix}, {TileRow}, {TileCol}",
             example:
               "\"https://example.com/wmts/{Layer}/{Style}/{TileMatrixSet}/{TileMatrix}/{TileRow}/{TileCol}.png\""
           )
  @type template :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Type describing a ResourceURL template for accessing tiles and resources",
             keys: %{
               format: ResourceURL,
               resource_type: ResourceURL,
               template: ResourceURL
             },
             example: """
             %ExWMTS.ResourceURL{
               format: "image/png",
               resource_type: "tile",
               template: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/layer/default/{TileMatrixSet}/{TileMatrix}/{TileRow}/{TileCol}.png"
             }
             """,
             related: [ExWMTS.Layer, ExWMTS.WMTSClient]
           )
  @type t :: %ResourceURL{
          format: format(),
          resource_type: resource_type(),
          template: template()
        }

  defstruct [:format, :resource_type, :template]

  @doc ExWMTS.Doc.func_doc("Builds ResourceURL structs from XML nodes or maps",
         params: %{resource_data: "XML node, map, list of nodes/maps, or nil to build into ResourceURL structs"}
       )
  @spec build(nil) :: nil
  @spec build([]) :: nil
  @spec build([map() | term()]) :: [ResourceURL.t()]
  @spec build(map() | term()) :: ResourceURL.t() | nil
  def build(nil), do: nil
  def build([]), do: nil

  def build(resource_nodes) when is_list(resource_nodes),
    do: Enum.map(resource_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(resource_node) do
    %ResourceURL{
      format: resource_node |> xpath(attribute("format")),
      resource_type: resource_node |> xpath(attribute("resourceType")),
      template: resource_node |> xpath(attribute("template"))
    }
  end
end
