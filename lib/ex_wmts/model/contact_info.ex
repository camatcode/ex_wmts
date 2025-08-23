defmodule ExWMTS.ContactInfo do
  @moduledoc ExWMTS.Doc.mod_doc("A struct describing contact details",
               example: """
               %ExWMTS.ContactInfo{
                 phone_voice: "+1 228 688-4972",
                 phone_facsimile: "+1 228 688-4853",
                 address_delivery_point: "1005 Balch Blvd Rm C-5",
                 address_city: "Stennis Space Center",
                 address_administrative_area: "MS",
                 address_postal_code: "39529",
                 address_country: "USA",
                 address_email: "norman.schoenhardt@nrlssc.navy.mil",
                 online_resource: "TBA",
                 hours_of_service: "8am-4:30pm cst mon-fri",
                 contact_instructions: "none"
               }
               """
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: ContactInfo

  defstruct [
    :phone_voice,
    :phone_facsimile,
    :address_delivery_point,
    :address_city,
    :address_administrative_area,
    :address_postal_code,
    :address_country,
    :address_email,
    :online_resource,
    :hours_of_service,
    :contact_instructions
  ]

  @typedoc ExWMTS.Doc.type_doc("Voice phone number", example: "\"+1 228 688-4972\"")
  @type phone_voice :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Facsimile phone number", example: "\"+1 228 688-4853\"")
  @type phone_facsimile :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Physical address delivery point", example: "\"1005 Balch Blvd Rm C-5\"")
  @type address_delivery_point :: String.t()

  @typedoc ExWMTS.Doc.type_doc("City name", example: "\"Stennis Space Center\"")
  @type address_city :: String.t()

  @typedoc ExWMTS.Doc.type_doc("State, province, or administrative area", example: "\"MS\"")
  @type address_administrative_area :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Postal or ZIP code", example: "\"39529\"")
  @type address_postal_code :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Country name", example: "\"USA\"")
  @type address_country :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Email address", example: "\"norman.schoenhardt@nrlssc.navy.mil\"")
  @type address_email :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Online resource URL", example: "\"TBA\"")
  @type online_resource :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Hours of service availability", example: "\"8am-4:30pm cst mon-fri\"")
  @type hours_of_service :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Special instructions for contacting", example: "\"none\"")
  @type contact_instructions :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Type describing contact information details",
             keys: %{
               phone_voice: ContactInfo,
               phone_facsimile: ContactInfo,
               address_delivery_point: ContactInfo,
               address_city: ContactInfo,
               address_administrative_area: ContactInfo,
               address_postal_code: ContactInfo,
               address_country: ContactInfo,
               address_email: ContactInfo,
               online_resource: ContactInfo,
               hours_of_service: ContactInfo,
               contact_instructions: ContactInfo
             },
             example: """
             %ExWMTS.ContactInfo{
               phone_voice: "+1 228 688-4972",
               phone_facsimile: "+1 228 688-4853",
               address_delivery_point: "1005 Balch Blvd Rm C-5",
               address_city: "Stennis Space Center",
               address_administrative_area: "MS",
               address_postal_code: "39529",
               address_country: "USA",
               address_email: "norman.schoenhardt@nrlssc.navy.mil",
               online_resource: "TBA",
               hours_of_service: "8am-4:30pm cst mon-fri",
               contact_instructions: "none"
             }
             """,
             related: [ExWMTS.ServiceProvider, ExWMTS.ServiceContact]
           )
  @type t :: %ContactInfo{
          phone_voice: phone_voice(),
          phone_facsimile: phone_facsimile(),
          address_delivery_point: address_delivery_point(),
          address_city: address_city(),
          address_administrative_area: address_administrative_area(),
          address_postal_code: address_postal_code(),
          address_country: address_country(),
          address_email: address_email(),
          online_resource: online_resource(),
          hours_of_service: hours_of_service(),
          contact_instructions: contact_instructions()
        }

  @doc ExWMTS.Doc.func_doc("Builds a `ContactInfo` from a map",
         params: %{m: "An XML node to build into a `t:ExWMTS.ContactInfo.t/0`"}
       )
  @spec build(info_node :: map) :: ContactInfo.t()
  def build(nil), do: nil

  def build(info_node) do
    make_contact_info(info_node)
    |> then(&struct(ContactInfo, &1))
  end

  defp make_contact_info(info_node) do
    %{
      phone_voice: info_node |> xpath(~x"./*[local-name()='Phone']/*[local-name()='Voice']/text()"s),
      phone_facsimile: info_node |> xpath(~x"./*[local-name()='Phone']/*[local-name()='Facsimile']/text()"s),
      address_delivery_point:
        info_node |> xpath(~x"./*[local-name()='Address']/*[local-name()='DeliveryPoint']/text()"s),
      address_city: info_node |> xpath(~x"./*[local-name()='Address']/*[local-name()='City']/text()"s),
      address_administrative_area:
        info_node |> xpath(~x"./*[local-name()='Address']/*[local-name()='AdministrativeArea']/text()"s),
      address_postal_code: info_node |> xpath(~x"./*[local-name()='Address']/*[local-name()='PostalCode']/text()"s),
      address_country: info_node |> xpath(~x"./*[local-name()='Address']/*[local-name()='Country']/text()"s),
      address_email:
        info_node |> xpath(~x"./*[local-name()='Address']/*[local-name()='ElectronicMailAddress']/text()"s),
      online_resource: info_node |> xpath(~x"./*[local-name()='OnlineResource']/@*[local-name()='href']"so),
      hours_of_service: info_node |> xpath(text("HoursOfService")),
      contact_instructions: info_node |> xpath(text("ContactInstructions"))
    }
  end
end
