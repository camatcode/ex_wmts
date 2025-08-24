defmodule ExWMTS.ServiceContact do
  @moduledoc ExWMTS.Doc.mod_doc("A struct describing a point of contact for the server",
               example: """
               %ExWMTS.ServiceContact{
                 individual_name: "Norman Schoenhardt",
                 position_name: "Computer Scientist",
                 contact_info: %ExWMTS.ContactInfo{
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
                 },
                 role: nil
               }
               """
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: ServiceContact
  alias ExWMTS.ContactInfo

  defstruct [:individual_name, :position_name, :contact_info, :role]

  @typedoc ExWMTS.Doc.type_doc("Name of the individual contact person", example: "\"Joan Mase Pau\"")
  @type individual_name :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Position or title of the contact person", example: "\"Senior Software Engineer\"")
  @type position_name :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Role of the contact person in the organization", example: "\"pointOfContact\"")
  @type role :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Contact information details for the service contact",
             example: ~s(%ExWMTS.ContactInfo{phone_voice: "+1 228 688-4972", address_city: "Stennis Space Center"})
           )
  @type contact_info :: ContactInfo.t()

  @typedoc ExWMTS.Doc.type_doc("Type describing a service contact person",
             keys: %{
               individual_name: ServiceContact,
               position_name: ServiceContact,
               contact_info: ServiceContact,
               role: ServiceContact
             },
             example: """
             %ExWMTS.ServiceContact{
               individual_name: "Norman Schoenhardt",
               position_name: "Computer Scientist",
               contact_info: %ExWMTS.ContactInfo{
                 phone_voice: "+1 228 688-4972",
                 phone_facsimile: "+1 228 688-4853",
                 address_delivery_point: "1005 Balch Blvd Rm C-5",
                 address_city: "Stennis Space Center",
                 address_administrative_area: "MS",
                 address_postal_code: "39529",
                 address_country: "USA",
                 address_email: "norman.schoenhardt@nrlssc.navy.mil"
               },
               role: nil
             }
             """,
             related: [ExWMTS.ServiceProvider, ExWMTS.ContactInfo]
           )
  @type t :: %ServiceContact{
          individual_name: individual_name(),
          position_name: position_name(),
          contact_info: contact_info(),
          role: role()
        }

  @doc ExWMTS.Doc.func_doc("Builds a `ServiceContact` from a map",
         params: %{m: "An XML node to build into a `t:ExWMTS.ServiceContact.t/0`"}
       )
  @spec build(contact_node :: map) :: ServiceContact.t()
  def build(nil), do: nil

  def build(contact_node) do
    %{
      individual_name: contact_node |> xpath(text("IndividualName")),
      position_name: contact_node |> xpath(text("PositionName")),
      contact_info: contact_node |> xpath(element("ContactInfo")) |> ContactInfo.build(),
      role: contact_node |> xpath(text("Role"))
    }
    |> then(&struct(ServiceContact, &1))
  end
end
