defmodule ExWMTS.Operation do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               Operation element describing a specific operation implemented by the WMTS server.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.1.2:

               "An Operation element describes the interface of one type of operation. The Operation element 
               includes the name of the operation, and the DCP (Distributed Computing Platform) where the 
               operation is available."
               """,
               example: """
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
               }
               """,
               related: [ExWMTS.OperationsMetadata, ExWMTS.DCP, ExWMTS.HTTP]
             )

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: Operation
  alias ExWMTS.DCP

  @typedoc ExWMTS.Doc.type_doc("Name of the operation", example: "\"GetCapabilities\"")
  @type name :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Type describing a WMTS operation",
             keys: %{
               name: Operation,
               dcp: {ExWMTS.DCP, :t}
             },
             example: """
             %ExWMTS.Operation{
               name: "GetCapabilities",
               dcp: %ExWMTS.DCP{
                 http: %ExWMTS.HTTP{
                   get: [%ExWMTS.HTTPMethod{href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi"}]
                 }
               }
             }
             """,
             related: [ExWMTS.OperationsMetadata, ExWMTS.DCP]
           )
  @type t :: %Operation{
          name: name(),
          dcp: DCP.t()
        }

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
