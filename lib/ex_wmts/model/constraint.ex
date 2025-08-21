defmodule ExWMTS.Constraint do
  @moduledoc """
  Constraint element defining valid parameter values for an operation or method.

  From OGC WMTS Implementation Standard (OGC 07-057r7) and OWS Common (OGC 06-121r9):

  "A Constraint element specifies a constraint on valid values of an operation parameter 
  or other item. The constraint can be specified using an allowed list of values or ranges."

  ## Required Elements

  - `name` - Name of the parameter being constrained

  ## Optional Elements

  - `allowed_values` - List of allowed values for this parameter

  ## Common Constraints

  From the WMTS standard, typical constraint names include:
  - "GetEncoding" - Valid request encoding methods (KVP, RESTful, SOAP)
  - "InfoFormat" - Supported GetFeatureInfo response formats
  - "Style" - Available style identifiers for layers

  ## Allowed Values

  The allowed_values list provides:
  - Enumerated valid parameter values
  - Format specifications (MIME types, versions)
  - Encoding method identifiers
  - Authentication scheme names

  ## Usage

  Constraints enable:
  - Client validation of request parameters
  - Service capability advertising  
  - Protocol negotiation between client and server
  - Error prevention through upfront validation

  This information helps clients construct valid requests and understand 
  the specific capabilities and limitations of each operation endpoint.
  """

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: Constraint

  defstruct [:name, :allowed_values]

  def build(nil), do: nil
  def build([]), do: nil

  def build(constraint_nodes) when is_list(constraint_nodes),
    do: Enum.map(constraint_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(constraint_node) do
    constraint_data =
      constraint_node
      |> xpath(~x".",
        name: attribute("name"),
        allowed_values: ~x"./*[local-name()='AllowedValues']/*[local-name()='Value']/text()"sl
      )

    name = normalize_text(constraint_data.name, nil)

    if name do
      allowed_values =
        constraint_data.allowed_values
        |> Enum.map(&normalize_text(&1, nil))
        |> Enum.reject(&is_nil/1)

      %Constraint{
        name: name,
        allowed_values: allowed_values
      }
    end
  end
end
