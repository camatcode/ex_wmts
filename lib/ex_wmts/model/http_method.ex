defmodule ExWMTS.HTTPMethod do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               HTTPMethod element specifying a URL endpoint and constraints for HTTP access.

               From OGC WMTS Implementation Standard (OGC 07-057r7) and OWS Common (OGC 06-121r9):

               "Each HTTP method (Get, Post) shall contain one or more OnlineResource elements that 
               specify the URL for the method, and optionally contain Constraint elements that 
               restrict the valid parameter values."

               ## Required Elements

               - `href` - URL endpoint for this HTTP method

               ## Optional Elements

               - `constraints` - List of Constraint elements defining valid parameter values

               ## URL Endpoints

               From the standard, href values provide:
               - Base URLs for KVP-encoded requests
               - RESTful URL templates with placeholder variables
               - SOAP/XML endpoint URLs for POST operations

               ## Constraints

               Constraint elements specify:
               - Valid encoding methods (KVP, RESTful, SOAP)
               - Supported format types and versions
               - Parameter validation rules
               - Authentication requirements

               This information enables clients to construct valid requests 
               and understand service capabilities and limitations.
               """,
               example: """
               %ExWMTS.HTTPMethod{
                 href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi",
                 constraints: [
                   %ExWMTS.Constraint{
                     name: "GetEncoding",
                     allowed_values: ["KVP"]
                   }
                 ]
               }
               """,
               related: [ExWMTS.HTTP, ExWMTS.Constraint]
             )

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: HTTPMethod
  alias ExWMTS.Constraint

  @typedoc ExWMTS.Doc.type_doc("URL endpoint for this HTTP method",
             example: "\"https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi\""
           )
  @type href :: String.t()

  @typedoc ExWMTS.Doc.type_doc("List of constraint elements defining valid parameter values",
             example: ~s([%ExWMTS.Constraint{name: "GetEncoding", allowed_values: ["KVP"]}])
           )
  @type constraints :: [Constraint.t()]

  @typedoc ExWMTS.Doc.type_doc("Type describing an HTTP method endpoint with constraints",
             keys: %{
               href: HTTPMethod,
               constraints: HTTPMethod
             },
             example: """
             %ExWMTS.HTTPMethod{
               href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi",
               constraints: [%ExWMTS.Constraint{name: "GetEncoding", allowed_values: ["KVP"]}]
             }
             """,
             related: [ExWMTS.HTTP, ExWMTS.Constraint]
           )
  @type t :: %HTTPMethod{
          href: href(),
          constraints: constraints()
        }

  defstruct [:href, :constraints]

  @doc ExWMTS.Doc.func_doc("Builds HTTPMethod structs from XML nodes or maps",
         params: %{method_data: "XML node, map, list of nodes/maps, or nil to build into HTTPMethod structs"}
       )
  @spec build(nil) :: nil
  @spec build([]) :: []
  @spec build([map() | term()]) :: [HTTPMethod.t()]
  @spec build(map() | term()) :: HTTPMethod.t() | nil
  def build(nil), do: nil
  def build([]), do: nil

  def build(method_nodes) when is_list(method_nodes), do: Enum.map(method_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(method_node) do
    method_data =
      method_node
      |> xpath(~x".",
        href: attribute("href"),
        constraints: element_list("Constraint")
      )

    href = normalize_text(method_data.href, nil)

    if href do
      constraints = Constraint.build(method_data.constraints)

      %HTTPMethod{
        href: href,
        constraints: constraints
      }
    end
  end
end
