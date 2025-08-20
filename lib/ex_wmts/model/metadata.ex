defmodule ExWMTS.Metadata do
  @moduledoc false

  import SweetXml

  alias __MODULE__, as: Metadata

  defstruct [:href, :about]

  def build(nil), do: nil
  def build([]), do: nil

  def build(metadata_nodes) when is_list(metadata_nodes),
    do: Enum.map(metadata_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(metadata_node) do
    %Metadata{
      href: metadata_node |> xpath(~x"./@*[local-name()='href']"s),
      about: metadata_node |> xpath(~x"./@about"s)
    }
  end
end
