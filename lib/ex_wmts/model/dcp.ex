defmodule ExWMTS.DCP do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               DCP (Distributed Computing Platform) element describing how to access an operation.

               From OGC WMTS Implementation Standard (OGC 07-057r7) and OWS Common (OGC 06-121r9):

               "The DCP element identifies a Distributed Computing Platform (DCP) supported for this 
               operation. At present, only the HTTP DCP is standardized."
               """,
               example: """
               %ExWMTS.DCP{
                  http: %ExWMTS.HTTP{
                    get: [
                      %ExWMTS.HTTPMethod{
                        href: "https://basemap.nationalmap.gov/arcgis/rest/services/USGSShadedReliefOnly/MapServer/WMTS/1.0.0/WMTSCapabilities.xml",
                        constraints: [
                          %ExWMTS.Constraint{
                            name: "GetEncoding",
                            allowed_values: ["RESTful"]
                          }
                        ]
                      },
                      %ExWMTS.HTTPMethod{
                        href: "https://basemap.nationalmap.gov/arcgis/rest/services/USGSShadedReliefOnly/MapServer/WMTS?",
                        constraints: [
                          %ExWMTS.Constraint{
                            name: "GetEncoding",
                            allowed_values: ["KVP"]
                          }
                        ]
                      }
                    ],
                    post: nil
                  }
               }
               """,
               related: [ExWMTS.Operation, ExWMTS.HTTP]
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: DCP
  alias ExWMTS.HTTP

  @typedoc ExWMTS.Doc.type_doc("Type describing Distributed Computing Platform access methods",
             keys: %{
               http: {ExWMTS.HTTP, :t}
             },
             example: """
               %ExWMTS.DCP{
                  http: %ExWMTS.HTTP{
                    get: [
                      %ExWMTS.HTTPMethod{
                        href: "https://basemap.nationalmap.gov/arcgis/rest/services/USGSShadedReliefOnly/MapServer/WMTS/1.0.0/WMTSCapabilities.xml",
                        constraints: [
                          %ExWMTS.Constraint{
                            name: "GetEncoding",
                            allowed_values: ["RESTful"]
                          }
                        ]
                      },
                      %ExWMTS.HTTPMethod{
                        href: "https://basemap.nationalmap.gov/arcgis/rest/services/USGSShadedReliefOnly/MapServer/WMTS?",
                        constraints: [
                          %ExWMTS.Constraint{
                            name: "GetEncoding",
                            allowed_values: ["KVP"]
                          }
                        ]
                      }
                    ],
                    post: nil
                  }
               }
             """,
             related: [ExWMTS.Operation, ExWMTS.HTTP]
           )
  @type t :: %DCP{
          http: ExWMTS.HTTP.t()
        }

  defstruct [:http]

  @doc ExWMTS.Doc.func_doc("Builds a `DCP` from a map",
         params: %{dcp_node: "An XML node to build into a `t:ExWMTS.DCP.t/0`"}
       )
  @spec build(dcp_node :: map) :: DCP.t()
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
