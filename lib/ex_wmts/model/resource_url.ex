defmodule ExWMTS.ResourceURL do
  @moduledoc """
  ResourceURL element providing template URLs for accessing tiles and resources.

  From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4.5:

  "A ResourceURL element identifies a URL template to be used for accessing resources. 
  A ResourceURL element may be used to provide alternative access methods for layers."

  ## Required Elements

  - `format` - MIME type of the resource (e.g., "image/png")
  - `resource_type` - Type of resource ("tile", "FeatureInfo")
  - `template` - URL template with placeholder variables

  ## URL Templates

  Template URLs contain placeholder variables:
  - {TileMatrixSet} - Identifier of the tile matrix set
  - {TileMatrix} - Identifier of the tile matrix
  - {TileRow} - Row index of the tile
  - {TileCol} - Column index of the tile
  - {Style} - Style identifier
  - {layer} - Layer identifier

  ## Resource Types

  From the standard:
  - "tile" - Template for accessing tile images
  - "FeatureInfo" - Template for accessing feature information

  This enables RESTful tile access without KVP parameter encoding.
  """

  import SweetXml

  alias __MODULE__, as: ResourceURL

  defstruct [:format, :resource_type, :template]

  def build(nil), do: nil
  def build([]), do: nil

  def build(resource_nodes) when is_list(resource_nodes),
    do: Enum.map(resource_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(resource_node) do
    %ResourceURL{
      format: resource_node |> xpath(~x"./@format"s),
      resource_type: resource_node |> xpath(~x"./@resourceType"s),
      template: resource_node |> xpath(~x"./@template"s)
    }
  end
end
