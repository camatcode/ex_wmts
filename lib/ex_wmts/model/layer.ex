defmodule ExWMTS.Layer do
  @moduledoc false
  import ExWMTS.Model.Common

  alias __MODULE__, as: Layer
  alias ExWMTS.{WGS84BoundingBox, BoundingBox, Metadata, Dimension, ResourceURL}

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
    resource_urls: []
  ]

  def build(m) when is_map(m) do
    case make_layer(m) do
      nil -> nil
      layer_map -> struct(Layer, layer_map)
    end
  end

  def build(nil), do: nil

  def build(layer_node) do
    make_layer(layer_node) |> build()
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
        formats: formats,
        tile_matrix_sets: tile_matrix_sets,
        styles: styles
      }
    end
  end
end
