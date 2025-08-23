defmodule ExWMTS.HTTP do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               HTTP binding element describing GET and POST access methods for an operation.

               From OGC WMTS Implementation Standard (OGC 07-057r7):

               "The HTTP element contains the access methods supported for this operation using the 
               HTTP protocol. Each HTTP method (Get, Post) shall contain one or more OnlineResource 
               elements that specify the URL for the method."

               ## Elements

               - `get` - List of HTTPMethod elements for GET request endpoints
               - `post` - List of HTTPMethod elements for POST request endpoints (if supported)

               ## HTTP Methods

               From the standard:
               - GET methods typically use KVP (Key-Value Pair) encoding in URL parameters
               - GET methods may also use RESTful URL templates for tile requests  
               - POST methods use XML or form-encoded request bodies
               - Each method includes URL endpoints and parameter constraints

               ## Encoding Support

               WMTS services commonly support:
               - KVP encoding: Parameters passed as URL query string
               - RESTful encoding: Tile parameters embedded in URL path structure  
               - SOAP/XML encoding: Structured XML requests via POST

               The choice of encoding affects how clients construct requests for 
               GetCapabilities, GetTile, and GetFeatureInfo operations.
               """,
               example: """
               %ExWMTS.HTTP{
                 get: [
                   %ExWMTS.HTTPMethod{
                     href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi"
                   }
                 ],
                 post: []
               }
               """,
               related: [ExWMTS.DCP, ExWMTS.HTTPMethod]
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: HTTP
  alias ExWMTS.HTTPMethod

  @typedoc ExWMTS.Doc.type_doc("List of HTTPMethod elements for GET request endpoints",
             example: "[%ExWMTS.HTTPMethod{href: \"https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi\"}]"
           )
  @type get_methods :: [HTTPMethod.t()]

  @typedoc ExWMTS.Doc.type_doc("List of HTTPMethod elements for POST request endpoints",
             example: "[]"
           )
  @type post_methods :: [HTTPMethod.t()]

  @typedoc ExWMTS.Doc.type_doc("GET method endpoints for HTTP operations",
             example: "[%ExWMTS.HTTPMethod{href: \"https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi\"}]"
           )
  @type get :: get_methods()

  @typedoc ExWMTS.Doc.type_doc("POST method endpoints for HTTP operations",
             example: "[]"
           )
  @type post :: post_methods()

  @typedoc ExWMTS.Doc.type_doc("HTTP binding with GET and POST access methods",
             example:
               "%ExWMTS.HTTP{get: [%ExWMTS.HTTPMethod{href: \"https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi\"}], post: []}"
           )
  @type http :: t()

  @typedoc ExWMTS.Doc.type_doc("Type describing HTTP binding access methods for WMTS operations",
             keys: %{
               get: HTTP,
               post: HTTP
             },
             example: """
             %ExWMTS.HTTP{
               get: [%ExWMTS.HTTPMethod{href: "https://gibs.earthdata.nasa.gov/wmts/epsg4326/best/wmts.cgi"}],
               post: []
             }
             """,
             related: [ExWMTS.DCP, ExWMTS.HTTPMethod]
           )
  @type t :: %HTTP{
          get: get_methods(),
          post: post_methods()
        }

  defstruct [:get, :post]

  def build(nil), do: nil

  def build(http_node) do
    http_data =
      http_node
      |> xpath(~x".",
        get: element_list("Get"),
        post: element_list("Post")
      )

    get_methods = HTTPMethod.build(http_data.get)
    post_methods = HTTPMethod.build(http_data.post)

    %HTTP{
      get: get_methods,
      post: post_methods
    }
  end
end
