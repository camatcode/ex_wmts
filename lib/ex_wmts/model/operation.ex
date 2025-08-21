defmodule ExWMTS.Operation do
  @moduledoc """
  Operation element describing a specific operation implemented by the WMTS server.

  From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.1.2:

  "An Operation element describes the interface of one type of operation. The Operation element 
  includes the name of the operation, and the DCP (Distributed Computing Platform) where the 
  operation is available."

  ## Required Elements

  - `name` - Name of the operation (GetCapabilities, GetTile, GetFeatureInfo)
  - `dcp` - Distributed Computing Platform access information

  ## Operation Names

  From the standard, valid operation names include:
  - "GetCapabilities" - Mandatory operation that returns service metadata
  - "GetTile" - Mandatory operation that returns a tile  
  - "GetFeatureInfo" - Optional operation that returns feature information

  The DCP element contains HTTP binding information including:
  - GET method endpoints and constraints
  - POST method endpoints and constraints (if supported)
  - Constraint elements defining valid parameter values
  """

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
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
        name: attribute("name"),
        dcp: element("DCP")
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
