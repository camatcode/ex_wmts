defmodule ExWMTS.ContactInfo do
  @moduledoc false

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
