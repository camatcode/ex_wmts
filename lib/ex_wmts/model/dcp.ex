defmodule ExWMTS.DCP do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
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
               """,
               example: """
               %ExWMTS.DCP{
                 http: %ExWMTS.HTTP{
                   get: [%ExWMTS.HTTPMethod{href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi"}],
                   post: []
                 }
               }
               """,
               related: [ExWMTS.Operation, ExWMTS.HTTP]
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: DCP
  alias ExWMTS.HTTP

  @typedoc ExWMTS.Doc.type_doc("HTTP access methods for distributed computing",
             example:
               "%ExWMTS.HTTP{get: [%ExWMTS.HTTPMethod{href: \"https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi\"}], post: []}"
           )
  @type http :: HTTP.t()

  @typedoc ExWMTS.Doc.type_doc("Distributed Computing Platform access methods",
             example:
               "%ExWMTS.DCP{http: %ExWMTS.HTTP{get: [%ExWMTS.HTTPMethod{href: \"https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi\"}], post: []}}"
           )
  @type dcp :: t()

  @typedoc ExWMTS.Doc.type_doc("Type describing Distributed Computing Platform access methods",
             keys: %{
               http: DCP
             },
             example: """
             %ExWMTS.DCP{
               http: %ExWMTS.HTTP{
                 get: [%ExWMTS.HTTPMethod{href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi"}],
                 post: []
               }
             }
             """,
             related: [ExWMTS.Operation, ExWMTS.HTTP]
           )
  @type t :: %DCP{
          http: http()
        }

  defstruct [:http]

  def build(nil), do: nil

  def build(dcp_node) do
    dcp_data =
      dcp_node
      |> xpath(~x".",
        http: element("HTTP")
      )

    http = HTTP.build(dcp_data.http)

    %DCP{
      http: http
    }
  end
end
