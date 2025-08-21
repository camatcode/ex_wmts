defmodule ExWMTS.DCP do
  @moduledoc """
  DCP (Distributed Computing Platform) element describing how to access an operation.

  From OGC WMTS Implementation Standard (OGC 07-057r7) and OWS Common (OGC 06-121r9):

  "The DCP element identifies a Distributed Computing Platform (DCP) supported for this 
  operation. At present, only the HTTP DCP is standardized."

  ## Required Elements

  - `http` - HTTP binding information for the operation

  ## HTTP Binding

  The HTTP element contains:
  - GET method endpoints and constraints
  - POST method endpoints and constraints (if supported)
  - URL endpoints for operation access
  - Parameter constraints and encoding information

  From the standard, HTTP bindings support:
  - KVP (Key-Value Pair) encoding via GET requests  
  - RESTful URL templates for tile access
  - POST requests with XML or form-encoded payloads

  This abstraction allows WMTS services to potentially support multiple 
  access protocols while currently focusing on HTTP-based access patterns.
  """

  import SweetXml

  alias __MODULE__, as: DCP
  alias ExWMTS.HTTP

  defstruct [:http]

  def build(nil), do: nil

  def build(dcp_node) do
    dcp_data =
      dcp_node
      |> xpath(~x".",
        http: ~x"./*[local-name()='HTTP']"e
      )

    http = HTTP.build(dcp_data.http)

    %DCP{
      http: http
    }
  end
end
