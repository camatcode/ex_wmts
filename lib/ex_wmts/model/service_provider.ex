defmodule ExWMTS.ServiceProvider do
  @moduledoc ExWMTS.Doc.mod_doc("A struct describing metadata about the organization operating the server",
               example: """
                 %ExWMTS.ServiceProvider{
                      provider_name: "UAB-CREAF-MiraMon",
                      provider_site: "http://www.creaf.uab.cat/miramon",
                      service_contact: %ExWMTS.ServiceContact{
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
                        },
                        role: ""
                      }
                    }
               """
             )

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: ServiceProvider
  alias ExWMTS.ServiceContact

  defstruct [:provider_name, :provider_site, :service_contact]

  @typedoc ExWMTS.Doc.type_doc("Unique identifier for service provider organization", example: "\"UAB-CREAF-MiraMon\"")
  @type provider_name :: String.t()

  @typedoc ExWMTS.Doc.type_doc("Reference to the most relevant web site of the service provider",
             example: "\"http://www.creaf.uab.cat/miramon\""
           )
  @type provider_site :: String.t()

  @type t :: %ServiceProvider{
          provider_name: provider_name(),
          provider_site: provider_site(),
          service_contact: ServiceContact.t()
        }

  @doc ExWMTS.Doc.func_doc("Builds a `ServiceProvider` from a map",
         params: %{m: "An XML node to build into a `t:ExWMTS.ServiceProvider.t/0`"}
       )
  @spec build(provider_node :: map) :: ServiceProvider.t()
  def build(nil), do: nil

  def build(provider_node) do
    %{
      provider_name: provider_node |> xpath(text("ProviderName")),
      provider_site: provider_node |> xpath(~x"./*[local-name()='ProviderSite']/@xlink:href"s),
      service_contact: provider_node |> xpath(element("ServiceContact")) |> ServiceContact.build()
    }
    |> then(&struct(ServiceProvider, &1))
  end
end
