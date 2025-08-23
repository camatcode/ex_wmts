defmodule ExWMTS.Metadata do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               Metadata element providing references to additional information about a layer.

               From OWS Common Specification (OGC 06-121r9), Section 11.2:

               "This metadata element is used for providing more information about the layer. 
               It should either use a reference to an external metadata document or provide 
               textual metadata information."
               """,
               example: """
               %ExWMTS.Metadata{
                 href: "https://gibs.earthdata.nasa.gov/colormaps/v1.3/MERRA2_2m_Air_Temperature_Monthly.xml",
                 about: ""
               }
               """,
               related: [ExWMTS.Layer]
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: Metadata

  @typedoc ExWMTS.Doc.type_doc("URL reference to external metadata document",
             example: "\"https://gibs.earthdata.nasa.gov/colormaps/v1.3/MERRA2_2m_Air_Temperature_Monthly.xml\""
           )
  @type href :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Textual description about what the metadata describes", example: "\"colormap\"")
  @type about :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Type describing metadata reference for a layer",
             keys: %{
               href: Metadata,
               about: Metadata
             },
             example: """
             %ExWMTS.Metadata{
               href: "https://gibs.earthdata.nasa.gov/colormaps/v1.3/MERRA2_2m_Air_Temperature_Monthly.xml",
               about: ""
             }
             """,
             related: [ExWMTS.Layer]
           )
  @type t :: %Metadata{
          href: href(),
          about: about()
        }

  defstruct [:href, :about]

  @doc ExWMTS.Doc.func_doc("Builds Metadata structs from XML nodes or maps",
         params: %{metadata_data: "XML node, map, list of nodes/maps, or nil to build into Metadata structs"}
       )
  @spec build(nil) :: nil
  @spec build([]) :: []
  @spec build([map() | term()]) :: [Metadata.t()]
  @spec build(map() | term()) :: Metadata.t() | nil
  def build(nil), do: nil
  def build([]), do: nil

  def build(metadata_nodes) when is_list(metadata_nodes),
    do: Enum.map(metadata_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(metadata_node) do
    %Metadata{
      href: metadata_node |> xpath(attribute("href")),
      about: metadata_node |> xpath(attribute("about"))
    }
  end
end
