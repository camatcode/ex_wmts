defmodule ExWMTS.Operation do
  @moduledoc false

  import ExWMTS.Model.Common
  import SweetXml

  alias __MODULE__, as: Operation
  alias ExWMTS.DCP

  defstruct [:name, :dcp]

  def build(nil), do: nil
  def build([]), do: nil

  def build(operation_nodes) when is_list(operation_nodes),
    do: Enum.map(operation_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(operation_node) do
    operation_data =
      operation_node
      |> xpath(~x".",
        name: ~x"./@name"s,
        dcp: ~x"./*[local-name()='DCP']"e
      )

    name = normalize_text(operation_data.name, nil)

    if name do
      dcp = DCP.build(operation_data.dcp)

      %Operation{
        name: name,
        dcp: dcp
      }
    end
  end
end
