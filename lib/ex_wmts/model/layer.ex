defmodule ExWMTS.Layer do
  @moduledoc """
  Layer element describing an individual layer served by a WMTS server.

  From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4:

  "A Layer element describes an individual layer served by a WMTS server. A Layer element shall have 
  an Identifier, Title, and one or more Format elements. The server shall list for each layer all the 
  TileMatrixSet elements that can be used to request tiles from the layer."

  ## Required Elements

  - `identifier` - Unique identifier for the layer
  - `title` - Human-readable title for the layer  
  - `formats` - List of MIME types supported for tiles of this layer
  - `tile_matrix_sets` - List of identifiers of TileMatrixSets applicable to this layer
  - `styles` - List of style identifiers applicable to this layer

  ## Optional Elements

  - `abstract` - Brief narrative description of the layer
  - `keywords` - List of descriptive keywords about the layer
  - `wgs84_bounding_box` - Minimum bounding rectangle in WGS84 longitude-latitude  
  - `bounding_box` - Minimum bounding rectangle in other coordinate reference systems
  - `metadata` - List of metadata references providing additional information
  - `dimensions` - List of dimension descriptions for multi-dimensional layers
  - `resource_urls` - List of resource URLs for different access patterns
  - `tile_matrix_set_links` - Links to TileMatrixSets with potential limits

  From Section 7.2.4.1: "The Format element shall indicate a supported output format for a tile. 
  The content of the element shall be a MIME type as defined by RFC 2046."
  """
  import ExWMTS.Model.Common

  alias __MODULE__, as: Layer
  alias ExWMTS.{BoundingBox, Dimension, Metadata, ResourceURL, TileMatrixSetLink, WGS84BoundingBox}

  defstruct [
    :identifier,
    :title,
    :abstract,
    :formats,
    :tile_matrix_sets,
    :styles,
    keywords: [],
    wgs84_bounding_box: nil,
    bounding_box: [],
    metadata: [],
    dimensions: [],
    resource_urls: [],
    tile_matrix_set_links: []
  ]

  def build(nil), do: nil
  def build([]), do: nil

  def build(layer_nodes) when is_list(layer_nodes) do
    layer_nodes
    |> Enum.map(&build/1)
    |> Enum.reject(&is_nil/1)
  end

  def build(m) when is_map(m) do
    case make_layer(m) do
      nil -> nil
      layer_map -> struct(Layer, layer_map)
    end
  end

  def build(layer_node) do
    layer = make_layer(layer_node)
    if layer, do: struct(Layer, layer)
  end

  defp make_layer(layer_data) do
    identifier = normalize_text(layer_data.identifier, nil)
    title = normalize_text(layer_data.title, identifier)
    abstract = normalize_text(layer_data.abstract, nil)

    keywords = layer_data.keywords || []
    wgs84_bounding_box = WGS84BoundingBox.build(layer_data.wgs84_bounding_box)
    bounding_box = BoundingBox.build(layer_data.bounding_box)
    metadata = Metadata.build(layer_data.metadata)
    dimensions = Dimension.build(layer_data.dimensions)
    resource_urls = ResourceURL.build(layer_data.resource_urls)
    tile_matrix_set_links = TileMatrixSetLink.build(layer_data.tile_matrix_set_links || [])

    formats = layer_data.formats |> Enum.map(&normalize_text/1) |> Enum.reject(&(&1 == nil)) |> Enum.uniq()
    tile_matrix_sets = layer_data.tile_matrix_sets |> Enum.map(&normalize_text/1) |> Enum.reject(&(&1 == nil))

    styles =
      layer_data.styles
      |> Enum.map(&normalize_text/1)
      |> Enum.reject(&(&1 == nil))
      |> case do
        [] -> ["default"]
        s -> s
      end
      |> Enum.uniq()

    if identifier != nil and !Enum.empty?(formats) do
      %{
        identifier: identifier,
        title: title,
        abstract: abstract,
        keywords: keywords,
        wgs84_bounding_box: wgs84_bounding_box,
        bounding_box: bounding_box,
        metadata: metadata,
        dimensions: dimensions,
        resource_urls: resource_urls,
        tile_matrix_set_links: tile_matrix_set_links,
        formats: formats,
        tile_matrix_sets: tile_matrix_sets,
        styles: styles
      }
    end
  end
end
