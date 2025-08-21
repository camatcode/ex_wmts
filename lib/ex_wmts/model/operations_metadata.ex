defmodule ExWMTS.OperationsMetadata do
  @moduledoc """
  Operations metadata section describing the operations implemented by the server.

  From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.1.2:

  "The OperationsMetadata section of a GetCapabilities operation response shall describe the 
  operations implemented by this server. This OperationsMetadata section shall include the 
  operations GetCapabilities, GetTile, and optionally GetFeatureInfo."

  ## Required Elements

  - `operations` - List of Operation elements describing implemented operations

  ## Standard Operations

  From Section 7.1.2.1: "The mandatory operations are:
  - GetCapabilities: Returns service metadata
  - GetTile: Returns a tile"

  From Section 7.1.2.2: "The optional operations are:
  - GetFeatureInfo: Returns information about features in a tile"

  Each Operation element describes:
  - Operation name (GetCapabilities, GetTile, GetFeatureInfo)
  - DCP (Distributed Computing Platform) access methods
  - HTTP binding information including GET and POST endpoints
  - Constraints and parameters for the operation
  """

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: OperationsMetadata
  alias ExWMTS.Operation

  defstruct [:operations]

  def build(nil), do: nil

  def build(operations_node) do
    operations_data =
      operations_node
      |> xpath(~x".",
        operations: element_list("Operation")
      )

    operations = Operation.build(operations_data.operations)

    %OperationsMetadata{
      operations: operations
    }
  end
end
