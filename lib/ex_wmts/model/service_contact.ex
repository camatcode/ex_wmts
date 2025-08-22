defmodule ExWMTS.ServiceContact do
  @moduledoc ExWMTS.Doc.mod_doc("A struct describing a point of contact for the server",
               example: """
               %ExWMTS.ServiceContact{
                  individual_name: "Joan Mase Pau",
                  position_name: "Senior Software Engineer",
                  contact_info: %ExWMTS.ContactInfo{
                      phone_voice: "+34 93 581 1310",
                      phone_facsimile: "+34 93 581 4150",
                      address_delivery_point: "Fac Ciencies UAB",
                      address_city: "Bellaterra",
                      address_administrative_area: "Barcelona",
                      address_postal_code: "08192",
                      address_country: "Spain",
                      address_email: "joan.mase@uab.dog",
                      online_resource: "",
                      hours_of_service: "",
                      contact_instructions: ""
                  }
               }
               """
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: ServiceContact
  alias ExWMTS.ContactInfo

  defstruct [:individual_name, :position_name, :contact_info, :role]

  @type individual_name :: String.t()

  @type position_name :: String.t()

  @type role :: String.t()

  @type t :: %ServiceContact{
          individual_name: individual_name(),
          position_name: position_name(),
          contact_info: ContactInfo.t(),
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
