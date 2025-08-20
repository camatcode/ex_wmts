defmodule ExWMTS.Layer do
  @moduledoc false
  import ExWMTS.Model.Common

  alias __MODULE__, as: Layer

  defstruct [:identifier, :title, :abstract, :formats, :tile_matrix_sets, :styles]

  def build(m) when is_map(m) do
    m
    |> then(&struct(Layer, &1))
  end

  def build(nil), do: nil

  def build(layer_node) do
    make_layer(layer_node) |> build()
  end

  defp make_layer(layer_data) do
    identifier = normalize_text(layer_data.identifier, nil)
    title = normalize_text(layer_data.title, identifier)
    abstract = normalize_text(layer_data.abstract, nil)

    formats =
      layer_data.formats
      |> Enum.map(&normalize_text/1)
      |> Enum.reject(&(&1 == nil))
      |> Enum.uniq()

    tile_matrix_sets =
      layer_data.tile_matrix_sets
      |> Enum.map(&normalize_text/1)
      |> Enum.reject(&(&1 == nil))

    styles =
      layer_data.styles
      |> Enum.map(&normalize_text/1)
      |> Enum.reject(&(&1 == nil))
      |> case do
        [] -> ["default"]
        styles -> styles
      end
      |> Enum.uniq()

    if identifier != nil and !Enum.empty?(formats) do
      %{
        identifier: identifier,
        title: title,
        abstract: abstract,
        formats: formats,
        tile_matrix_sets: tile_matrix_sets,
        styles: styles
      }
    end
  end
end
