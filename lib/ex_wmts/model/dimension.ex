defmodule ExWMTS.Dimension do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               Dimension element describing additional parameters for multi-dimensional layers.

               From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.2.4.3:

               "A Dimension element describes an additional parameter for the layer. This parameter is 
               commonly used for multidimensional datasets where tile contents vary along additional 
               dimensions such as time, elevation, or other environmental parameters."
               """,
               example: """
               %ExWMTS.Dimension{
                 identifier: "Time",
                 title: "",
                 abstract: "",
                 units_symbol: "",
                 unit_symbol: "",
                 default: "2025-06-05",
                 current: "",
                 values: ["1980-01-01/2023-11-01/P1M", "2025-01-01/2025-04-01/P1M"]
               }
               """,
               related: [ExWMTS.Layer, ExWMTS.ResourceURL]
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: Dimension

  @typedoc ExWMTS.Doc.type_doc("Unique identifier for this dimension", example: "\"Time\"")
  @type dimension_identifier :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Human-readable title for the dimension", example: "\"Time Dimension\"")
  @type title :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Brief narrative description of the dimension",
             example: "\"Temporal dimension for time-varying data\""
           )
  @type abstract :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Symbol of the units", example: "\"ISO8601\"")
  @type units_symbol :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Symbol of the units (alternative spelling)", example: "\"ISO8601\"")
  @type unit_symbol :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Default value for this dimension", example: "\"2025-06-05\"")
  @type default :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Current value for this dimension", example: "\"2025-06-05\"")
  @type current :: String.t()

  @typedoc ExWMTS.Doc.type_doc("List of valid values or ranges for this dimension",
             example: ~s(["1980-01-01/2023-11-01/P1M", "2025-01-01/2025-04-01/P1M"])
           )
  @type values :: [String.t()]

  @typedoc ExWMTS.Doc.type_doc("Type describing an additional dimension parameter for layers",
             keys: %{
               identifier: {Dimension, :dimension_identifier},
               title: Dimension,
               abstract: Dimension,
               units_symbol: Dimension,
               unit_symbol: Dimension,
               default: Dimension,
               current: Dimension,
               values: Dimension
             },
             example: """
             %ExWMTS.Dimension{
               identifier: "Time",
               default: "2025-06-05",
               values: ["1980-01-01/2023-11-01/P1M", "2025-01-01/2025-04-01/P1M"]
             }
             """,
             related: [ExWMTS.Layer, ExWMTS.ResourceURL]
           )
  @type t :: %Dimension{
          identifier: dimension_identifier(),
          title: title(),
          abstract: abstract(),
          units_symbol: units_symbol(),
          unit_symbol: unit_symbol(),
          default: default(),
          current: current(),
          values: values()
        }

  defstruct [:identifier, :title, :abstract, :units_symbol, :unit_symbol, :default, :current, :values]

  @doc ExWMTS.Doc.func_doc("Builds Dimension structs from XML nodes or maps",
         params: %{dimension_data: "XML node, map, list of nodes/maps, or nil to build into Dimension structs"}
       )
  @spec build(nil) :: nil
  @spec build([]) :: []
  @spec build([map() | term()]) :: [Dimension.t()]
  @spec build(map() | term()) :: Dimension.t() | nil
  def build(nil), do: nil
  def build([]), do: nil

  def build(dimension_nodes) when is_list(dimension_nodes),
    do: Enum.map(dimension_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(dim_node) do
    %Dimension{
      identifier: dim_node |> xpath(text("Identifier")),
      title: dim_node |> xpath(text("Title")),
      abstract: dim_node |> xpath(text("Abstract")),
      units_symbol: dim_node |> xpath(attribute("unitsSymbol")),
      unit_symbol: dim_node |> xpath(attribute("unitSymbol")),
      default: dim_node |> xpath(text("Default")),
      current: dim_node |> xpath(attribute("current")),
      values: dim_node |> xpath(text_list("Value"))
    }
  end
end
