defmodule ExWMTS.TileMatrixSet do
  @moduledoc false

  import ExWMTS.Model.Common
  import SweetXml

  alias __MODULE__, as: TileMatrixSet
  alias ExWMTS.BoundingBox

  defstruct [:identifier, :title, :abstract, :keywords, :supported_crs, :bounding_box, :well_known_scale_set, :matrices]

  def build(nil), do: nil

  def build(tms_node) do
    set = make_tile_matrix_set(tms_node)
    if set, do: struct(TileMatrixSet, set)
  end

  defp make_tile_matrix_set(tms_node) do
    tms_data =
      tms_node
      |> xpath(~x".",
        identifier: ~x"./*[local-name()='Identifier']/text()"s,
        title: ~x"./*[local-name()='Title']/text()"s,
        abstract: ~x"./*[local-name()='Abstract']/text()"s,
        keywords: ~x"./*[local-name()='Keywords']/*[local-name()='Keyword']/text()"sl,
        supported_crs: ~x"./*[local-name()='SupportedCRS']/text()"s,
        bounding_box: ~x"./*[local-name()='BoundingBox']"e,
        well_known_scale_set: ~x"./*[local-name()='WellKnownScaleSet']/text()"s,
        matrices: ~x"./*[local-name()='TileMatrix']"el
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
