defmodule ExWMTS.TileMatrixSet do
  @moduledoc """
  TileMatrixSet defining a tiling scheme for a coordinate reference system.

  From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.3:

  "A TileMatrixSet defines a particular tiling scheme for a coordinate reference system. It contains 
  the TileMatrix definitions that define the tiling schemes for each scale and the spatial extent 
  (BoundingBox) that contains all the tiles."

  ## Required Elements

  - `identifier` - Unique identifier for this TileMatrixSet
  - `supported_crs` - Coordinate reference system identifier (e.g., "EPSG:4326")
  - `matrices` - List of TileMatrix elements defining the tiling scheme at different scales

  ## Optional Elements

  - `title` - Human-readable title for the TileMatrixSet
  - `abstract` - Brief narrative description of the TileMatrixSet  
  - `keywords` - List of descriptive keywords
  - `bounding_box` - Minimum bounding rectangle applicable to this TileMatrixSet
  - `well_known_scale_set` - Well-known identifier for a scale set

  From Section 7.2.3.1: "The SupportedCRS element shall indicate the coordinate reference system 
  used by this TileMatrixSet. The coordinate reference system shall be described by reference to 
  its identifier."

  From Section 7.2.3.2: "A TileMatrix defines how space is partitioned into a set of square tiles. 
  The TileMatrix defines a particular tile matrix by defining its limits (MatrixWidth, MatrixHeight), 
  the tile size (TileWidth, TileHeight) and geospatial metadata."
  """

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: TileMatrixSet
  alias ExWMTS.BoundingBox

  defstruct [:identifier, :title, :abstract, :keywords, :supported_crs, :bounding_box, :well_known_scale_set, :matrices]

  def build(nil), do: nil

  def build([]), do: nil

  def build(tms_nodes) when is_list(tms_nodes) do
    tms_nodes
    |> Enum.map(&build/1)
    |> Enum.reject(&is_nil/1)
  end

  def build(tms_node) do
    set = make_tile_matrix_set(tms_node)
    if set, do: struct(TileMatrixSet, set)
  end

  defp make_tile_matrix_set(tms_node) do
    tms_data =
      tms_node
      |> xpath(~x".",
        identifier: text("Identifier"),
        title: text("Title"),
        abstract: text("Abstract"),
        keywords: ~x"./*[local-name()='Keywords']/*[local-name()='Keyword']/text()"sl,
        supported_crs: text("SupportedCRS"),
        bounding_box: element("BoundingBox"),
        well_known_scale_set: text("WellKnownScaleSet"),
        matrices: element_list("TileMatrix")
      )

    identifier = normalize_text(tms_data.identifier, nil)

    if identifier do
      title = normalize_text(tms_data.title, nil)
      abstract = normalize_text(tms_data.abstract, nil)
      keywords = tms_data.keywords |> Enum.map(&normalize_text(&1, nil)) |> Enum.reject(&is_nil/1)
      supported_crs = normalize_text(tms_data.supported_crs, "EPSG:4326")
      bounding_box = BoundingBox.build(tms_data.bounding_box)
      well_known_scale_set = normalize_text(tms_data.well_known_scale_set, nil)

      matrices =
        tms_data.matrices
        |> Enum.map(&ExWMTS.TileMatrix.build/1)
        |> Enum.reject(&(&1 == nil or &1.identifier == nil))

      %{
        identifier: identifier,
        title: title,
        abstract: abstract,
        keywords: keywords,
        supported_crs: supported_crs,
        bounding_box: bounding_box,
        well_known_scale_set: well_known_scale_set,
        matrices: matrices
      }
    end
  end
end
