defmodule ExWMTS.Dimension do
  @moduledoc false

  import SweetXml

  defstruct [:identifier, :title, :abstract, :units_symbol, :unit_symbol, :default, :current, :values]

  def build(nil), do: []
  def build([]), do: []

  def build(dimension_nodes) when is_list(dimension_nodes),
    do: Enum.map(dimension_nodes, &build_single/1) |> Enum.reject(&is_nil/1)

  def build(dimension_node),
    do:
      case(build_single(dimension_node),
        do: (
          nil -> []
          dim -> [dim]
        )
      )

  defp build_single(dim_node) do
    identifier = dim_node |> xpath(~x"./*[local-name()='Identifier']/text()"s)

    case identifier do
      "" ->
        nil

      _ ->
        %__MODULE__{
          identifier: identifier,
          title: dim_node |> xpath(~x"./*[local-name()='Title']/text()"s),
          abstract: dim_node |> xpath(~x"./*[local-name()='Abstract']/text()"s),
          units_symbol: dim_node |> xpath(~x"./@unitsSymbol"s),
          unit_symbol: dim_node |> xpath(~x"./@unitSymbol"s),
          default: dim_node |> xpath(~x"./*[local-name()='Default']/text()"s),
          current: dim_node |> xpath(~x"./@current"s),
          values: dim_node |> xpath(~x"./*[local-name()='Value']/text()"sl)
        }
    end
  end
end
