defmodule ExWMTS.OperationsMetadata do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               Operations metadata section describing the operations implemented by the server.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.1.2:

               "The OperationsMetadata section of a GetCapabilities operation response shall describe the 
               operations implemented by this server. This OperationsMetadata section shall include the 
               operations GetCapabilities, GetTile, and optionally GetFeatureInfo."
               """,
               example: """
               %ExWMTS.OperationsMetadata{
                 operations: [
                   %ExWMTS.Operation{
                     name: "GetCapabilities",
                     dcp: %ExWMTS.DCP{
                       http: %ExWMTS.HTTP{
                         get: [
                           %ExWMTS.HTTPMethod{
                             href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi?",
                             constraints: [
                               %ExWMTS.Constraint{name: "GetEncoding", allowed_values: ["KVP"]}
                             ]
                           }
                         ],
                         post: nil
                       }
                     }
                   },
                   %ExWMTS.Operation{
                     name: "GetTile",
                     dcp: %ExWMTS.DCP{
                       http: %ExWMTS.HTTP{
                         get: [
                           %ExWMTS.HTTPMethod{
                             href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi?",
                             constraints: [
                               %ExWMTS.Constraint{name: "GetEncoding", allowed_values: ["KVP"]}
                             ]
                           }
                         ],
                         post: nil
                       }
                     }
                   }
                 ]
               }
               """,
               related: [ExWMTS.Operation, ExWMTS.CapabilitiesParser]
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: OperationsMetadata
  alias ExWMTS.Operation

  @typedoc ExWMTS.Doc.type_doc("List of Operation elements describing implemented operations",
             example: ~s([%ExWMTS.Operation{name: "GetCapabilities"}, %ExWMTS.Operation{name: "GetTile"}])
           )
  @type operations :: [Operation.t()]

  @typedoc ExWMTS.Doc.type_doc("Type describing operations metadata for a WMTS server",
             keys: %{
               operations: {ExWMTS.Operation, :t, :list}
             },
             example: """
             %ExWMTS.OperationsMetadata{
               operations: [
                 %ExWMTS.Operation{
                   name: "GetCapabilities",
                   dcp: %ExWMTS.DCP{
                     http: %ExWMTS.HTTP{
                       get: [%ExWMTS.HTTPMethod{href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi?"}]
                     }
                   }
                 },
                 %ExWMTS.Operation{
                   name: "GetTile",
                   dcp: %ExWMTS.DCP{
                     http: %ExWMTS.HTTP{
                       get: [%ExWMTS.HTTPMethod{href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi?"}]
                     }
                   }
                 }
               ]
             }
             """,
             related: [ExWMTS.Operation, ExWMTS.CapabilitiesParser]
           )
  @type t :: %OperationsMetadata{
          operations: operations()
        }

  defstruct [:operations]

  @doc ExWMTS.Doc.func_doc("Builds OperationsMetadata struct from XML node or map",
         params: %{metadata_data: "XML node, map, or nil to build into OperationsMetadata struct"}
       )
  @spec build(nil) :: nil
  @spec build(map() | term()) :: OperationsMetadata.t() | nil
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
