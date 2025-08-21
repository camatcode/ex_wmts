defmodule ExWMTS.OperationsMetadata do
  @moduledoc false

  import SweetXml

  alias __MODULE__, as: OperationsMetadata
  alias ExWMTS.Operation

  defstruct [:operations]

  def build(nil), do: nil

  def build(operations_node) do
    operations_data =
      operations_node
      |> xpath(~x".",
        operations: ~x"./*[local-name()='Operation']"el
      )

    operations = Operation.build(operations_data.operations)

    %OperationsMetadata{
      operations: operations
    }
  end
end
