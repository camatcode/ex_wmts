defmodule ExWMTS.HTTP do
  @moduledoc """
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
  """

  import SweetXml

  alias __MODULE__, as: HTTP
  alias ExWMTS.HTTPMethod

  defstruct [:get, :post]

  def build(nil), do: nil

  def build(http_node) do
    http_data =
      http_node
      |> xpath(~x".",
        get: ~x"./*[local-name()='Get']"el,
        post: ~x"./*[local-name()='Post']"el
      )

    get_methods = HTTPMethod.build(http_data.get)
    post_methods = HTTPMethod.build(http_data.post)

    %HTTP{
      get: get_methods,
      post: post_methods
    }
  end
end
