defmodule ExWMTS.ServiceIdentification do
  @moduledoc ExWMTS.Doc.mod_doc(
               """
               A struct describing an OGC ServiceIdentification
               """,
               example: """
               %ExWMTS.ServiceIdentification{
                title: "World example Web Map Tile Service",
                abstract: "Example service that constrains some world layers",
                keywords: ["World", "Global", "Digital Elevation Model","Administrative Boundaries"],
                service_type: "OGC WMTS",
                service_type_version: "1.0.0",
                profile: [],
                fees: "none",
                access_constraints: "none"
               }
               """,
               related: [ExWMTS.CapabilitiesParser]
             )
  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: ServiceIdentification

  defstruct title: "Unknown Service",
            abstract: nil,
            keywords: [],
            service_type: "WMTS",
            service_type_version: "1.0.0",
            profile: [],
            fees: "none",
            access_constraints: "none"

  @typedoc ExWMTS.Doc.type_doc("Identifier of OGC Web Service Application Profile")
  @type profile :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Title of this dataset, normally used for display to a human",
             example: "\"World example Web Map Tile Service\""
           )
  @type title :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Brief narrative description of this layer, normally available for display to a human",
             example: "\"Example service that constrains some world layers\""
           )
  @type abstract :: String.t()

  @typedoc ExWMTS.Doc.type_doc(
             "Unordered list of one or more commonly used or formalised word(s) or phrase(s) used to describe this dataset",
             example: """
              ["World", "Global", "Digital Elevation Model","Administrative Boundaries"]
             """
           )
  @type keywords :: [String.t()]

  @typedoc ExWMTS.Doc.type_doc("Identifies the type of service", example: "\"WMTS\"")
  @type service_type :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Versions of this service type implemented by the server", example: "\"1.0.0\"")
  @type service_type_version :: String.t()

  @typedoc ExWMTS.Doc.type_doc(
             "Fees and terms for using the server, including the monetary units as specified in ISO 4217",
             example: "\"none\""
           )
  @type fees :: String.t()

  @typedoc ExWMTS.Doc.type_doc(
             "Access constraints that should be observed to assure the protection of privacy or intellectual property, and any other restrictions on retrieving or using data from or otherwise using the server",
             example: "\"none\""
           )
  @type access_constraints :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Type describing metadata about this specific server.",
             keys: %{
               title: ServiceIdentification,
               abstract: ServiceIdentification,
               keywords: ServiceIdentification,
               service_type: ServiceIdentification,
               service_type_version: ServiceIdentification,
               profile: {ServiceIdentification, :profile, :list},
               fees: ServiceIdentification,
               access_constraints: ServiceIdentification
             },
             example: """
              %ExWMTS.ServiceIdentification{
                title: "World example Web Map Tile Service",
                abstract: "Example service that constrains some world layers",
                keywords: ["World", "Global", "Digital Elevation Model","Administrative Boundaries"],
                service_type: "OGC WMTS",
                service_type_version: "1.0.0",
                profile: [],
                fees: "none",
                access_constraints: "none"
              }
             """,
             related: [ExWMTS.CapabilitiesParser]
           )
  @type t :: %ServiceIdentification{
          title: title(),
          abstract: abstract(),
          keywords: keywords(),
          service_type: service_type(),
          service_type_version: service_type_version(),
          profile: [profile()],
          fees: fees(),
          access_constraints: access_constraints()
        }

  @doc ExWMTS.Doc.func_doc("Builds a `ServiceIdentification` from a map",
         params: %{m: "An XML node to build into a `t:ExWMTS.ServiceIdentification.t/0`"}
       )
  @spec build(service_node :: map) :: ServiceIdentification.t()
  def build(nil), do: build(%{})

  def build(service_node) do
    %{
      title: service_node |> xpath(text("Title")),
      abstract: service_node |> xpath(text("Abstract")),
      keywords: service_node |> xpath(~x"./*[local-name()='Keywords']/*[local-name()='Keyword']/text()"sl),
      service_type: service_node |> xpath(text("ServiceType")),
      service_type_version: service_node |> xpath(text("ServiceTypeVersion")),
      profile: service_node |> xpath(text_list("Profile")),
      fees: service_node |> xpath(text("Fees")),
      access_constraints: service_node |> xpath(text("AccessConstraints"))
    }
    |> then(&struct(ServiceIdentification, &1))
  end
end
