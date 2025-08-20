defmodule ExWMTS.ResourceURL do
  @moduledoc false

  import SweetXml

  alias __MODULE__, as: ResourceURL

  defstruct [:format, :resource_type, :template]

  def build(nil), do: nil
  def build([]), do: nil

  def build(resource_nodes) when is_list(resource_nodes),
    do: Enum.map(resource_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(resource_node) do
    %ResourceURL{
      format: resource_node |> xpath(~x"./@format"s),
      resource_type: resource_node |> xpath(~x"./@resourceType"s),
      template: resource_node |> xpath(~x"./@template"s)
    }
  end
end
