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
                  keywords: [],
                  uom: "ISO8601",
                  unit_symbol: "",
                  default: "2025-06-05",
                  current: "false",
                  values: ["1980-01-01/2023-11-01/P1M", "2025-01-01/2025-04-01/P1M",
                    "2025-04-08/2025-04-08/P1M", "2025-04-09/2025-04-09/P1M",
                    "2025-04-10/2025-04-10/P1M", "2025-04-11/2025-04-11/P1M",
                    "2025-04-12/2025-04-12/P1M", "2025-04-13/2025-04-13/P1M",
                    "2025-04-14/2025-04-14/P1M", "2025-04-15/2025-04-15/P1M",
                    "2025-04-16/2025-04-16/P1M", "2025-04-17/2025-04-17/P1M",
                    "2025-04-18/2025-04-18/P1M", "2025-04-19/2025-04-19/P1M",
                    "2025-04-20/2025-04-20/P1M", "2025-04-21/2025-04-21/P1M",
                    "2025-04-22/2025-04-22/P1M", "2025-04-23/2025-04-23/P1M",
                    "2025-04-24/2025-04-24/P1M", "2025-04-25/2025-04-25/P1M",
                    "2025-04-26/2025-04-26/P1M", "2025-04-27/2025-04-27/P1M",
                    "2025-04-28/2025-04-28/P1M", ...]
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

  @typedoc ExWMTS.Doc.type_doc("List of descriptive keywords", example: ~s(["temporal", "time-series"]))
  @type keywords :: [String.t()]

  @typedoc ExWMTS.Doc.type_doc("Unit of measure identifier", example: "\"ISO8601\"")
  @type uom :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Unit symbol for this dimension", example: "\"ISO8601\"")
  @type unit_symbol :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Default value for this dimension", example: "\"2025-06-05\"")
  @type default :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Current value for this dimension", example: "\"false\"")
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
               keywords: Dimension,
               uom: Dimension,
               unit_symbol: Dimension,
               default: Dimension,
               current: Dimension,
               values: Dimension
             },
             example: """
               %ExWMTS.Dimension{
                  identifier: "Time",
                  title: "",
                  abstract: "",
                  keywords: [],
                  uom: "ISO8601",
                  unit_symbol: "",
                  default: "2025-06-05",
                  current: "false",
                  values: ["1980-01-01/2023-11-01/P1M", "2025-01-01/2025-04-01/P1M",
                    "2025-04-08/2025-04-08/P1M", "2025-04-09/2025-04-09/P1M",
                    "2025-04-10/2025-04-10/P1M", "2025-04-11/2025-04-11/P1M",
                    "2025-04-12/2025-04-12/P1M", "2025-04-13/2025-04-13/P1M",
                    "2025-04-14/2025-04-14/P1M", "2025-04-15/2025-04-15/P1M",
                    "2025-04-16/2025-04-16/P1M", "2025-04-17/2025-04-17/P1M",
                    "2025-04-18/2025-04-18/P1M", "2025-04-19/2025-04-19/P1M",
                    "2025-04-20/2025-04-20/P1M", "2025-04-21/2025-04-21/P1M",
                    "2025-04-22/2025-04-22/P1M", "2025-04-23/2025-04-23/P1M",
                    "2025-04-24/2025-04-24/P1M", "2025-04-25/2025-04-25/P1M",
                    "2025-04-26/2025-04-26/P1M", "2025-04-27/2025-04-27/P1M",
                    "2025-04-28/2025-04-28/P1M", ...]
               }
             """,
             related: [ExWMTS.Layer, ExWMTS.ResourceURL]
           )
  @type t :: %Dimension{
          identifier: dimension_identifier(),
          title: title(),
          abstract: abstract(),
          keywords: keywords(),
          uom: uom(),
          unit_symbol: unit_symbol(),
          default: default(),
          current: current(),
          values: values()
        }

  defstruct [:identifier, :title, :abstract, :keywords, :uom, :unit_symbol, :default, :current, :values]

  @doc ExWMTS.Doc.func_doc("Builds Dimension structs from XML nodes or maps",
         params: %{dimension_data: "XML node, map, list of nodes/maps, or nil to build into Dimension structs"}
       )
  @spec build(map()) :: Dimension.t() | [Dimension.t()] | nil
  def build(nil), do: nil
  def build([]), do: nil

  def build(dimension_nodes) when is_list(dimension_nodes),
    do: Enum.map(dimension_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(dim_node) do
    %Dimension{
      identifier: dim_node |> xpath(text("Identifier")),
      title: dim_node |> xpath(text("Title")),
      abstract: dim_node |> xpath(text("Abstract")),
      keywords: dim_node |> xpath(~x"./*[local-name()='Keywords']/*[local-name()='Keyword']/text()"sl),
      uom: dim_node |> xpath(text("UOM")),
      unit_symbol: dim_node |> xpath(attribute("UnitSymbol")),
      default: dim_node |> xpath(text("Default")),
      current: dim_node |> xpath(text("Current")),
      values: dim_node |> xpath(text_list("Value"))
    }
  end
end
