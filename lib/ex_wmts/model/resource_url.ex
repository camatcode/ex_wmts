defmodule ExWMTS.ResourceURL do
  @moduledoc false

  import SweetXml

  defstruct [:format, :resource_type, :template]

  def build(nil), do: []
  def build([]), do: []

  def build(resource_nodes) when is_list(resource_nodes),
    do: Enum.map(resource_nodes, &build_single/1) |> Enum.reject(&is_nil/1)

  def build(resource_node),
    do:
      case(build_single(resource_node),
        do: (
          nil -> []
          url -> [url]
        )
      )

  defp build_single(node) do
    template = node |> xpath(~x"./@template"s)

    case template do
      "" ->
        nil

      _ ->
        %__MODULE__{
          format: node |> xpath(~x"./@format"s),
          resource_type: node |> xpath(~x"./@resourceType"s),
          template: template
        }
    end
  end
end
