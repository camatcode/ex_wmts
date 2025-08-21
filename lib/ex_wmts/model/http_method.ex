defmodule ExWMTS.HTTPMethod do
  @moduledoc """
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
  """

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: HTTPMethod
  alias ExWMTS.Constraint

  defstruct [:href, :constraints]

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
