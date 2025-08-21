defmodule ExWMTS.Dimension do
  @moduledoc false

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: Dimension

  defstruct [:identifier, :title, :abstract, :units_symbol, :unit_symbol, :default, :current, :values]

  def build(nil), do: nil
  def build([]), do: nil

  def build(dimension_nodes) when is_list(dimension_nodes),
    do: Enum.map(dimension_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(dim_node) do
    %Dimension{
      identifier: dim_node |> xpath(text("Identifier")),
      title: dim_node |> xpath(text("Title")),
      abstract: dim_node |> xpath(text("Abstract")),
      units_symbol: dim_node |> xpath(attribute("unitsSymbol")),
      unit_symbol: dim_node |> xpath(attribute("unitSymbol")),
      default: dim_node |> xpath(text("Default")),
      current: dim_node |> xpath(attribute("current")),
      values: dim_node |> xpath(text_list("Value"))
    }
  end
end
