defmodule ExWMTS.Constraint do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               Constraint element defining valid parameter values for an operation or method.

               From OGC WMTS Implementation Standard (OGC 07-057r7) and OWS Common (OGC 06-121r9):

               "A Constraint element specifies a constraint on valid values of an operation parameter 
               or other item. The constraint can be specified using an allowed list of values or ranges."
               """,
               example: """
               %ExWMTS.Constraint{
                 name: "GetEncoding", 
                 allowed_values: ["KVP"]
               }
               """,
               related: [ExWMTS.Operation, ExWMTS.HTTPMethod]
             )

  import ExWMTS.Model.Common
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: Constraint

  @typedoc ExWMTS.Doc.type_doc("Name identifier for this constraint", example: "\"GetEncoding\"")
  @type constraint_name :: String.t()

  @typedoc ExWMTS.Doc.type_doc("List of allowed values for this constraint", example: ~s(["KVP", "RESTful"]))
  @type allowed_values :: [String.t()]

  @typedoc ExWMTS.Doc.type_doc("Type describing constraint on valid parameter values",
             keys: %{
               name: {Constraint, :constraint_name},
               allowed_values: Constraint
             },
             example: """
             %ExWMTS.Constraint{
               name: "GetEncoding",
               allowed_values: ["KVP"]
             }
             """,
             related: [ExWMTS.Operation, ExWMTS.HTTPMethod]
           )
  @type t :: %Constraint{
          name: constraint_name(),
          allowed_values: allowed_values()
        }

  defstruct [:name, :allowed_values]

  @doc ExWMTS.Doc.func_doc("Builds Constraint struct(s) from XML node(s)",
         params: %{constraint_nodes: "XML node(s) to build into Constraint struct(s)"}
       )

  @spec build(map()) :: Constraint.t() | [Constraint.t()] | nil
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
