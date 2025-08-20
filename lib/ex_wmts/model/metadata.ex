defmodule ExWMTS.Metadata do
  @moduledoc false

  import SweetXml

  defstruct [:href, :about]

  def build(nil), do: []
  def build([]), do: []

  def build(metadata_nodes) when is_list(metadata_nodes),
    do: Enum.map(metadata_nodes, &build_single/1) |> Enum.reject(&is_nil/1)

  def build(metadata_node),
    do:
      case(build_single(metadata_node),
        do: (
          nil -> []
          meta -> [meta]
        )
      )

  defp build_single(node) do
    href = node |> xpath(~x"./@*[local-name()='href']"s)

    case href do
      "" -> nil
      _ -> %__MODULE__{href: href, about: node |> xpath(~x"./@about"s)}
    end
  end
end
