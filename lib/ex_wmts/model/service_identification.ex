defmodule ExWMTS.ServiceIdentification do
  @moduledoc """
  Service identification section providing metadata that allows the categorization of a service 
  and enables discovery and evaluation of the provided service.

  From OGC WMTS Implementation Standard (OGC 07-057r7), Section 7.1.1:

  "The service identification section of a WMTS capabilities document shall include the elements 
  specified in OWS Common [OGC 06-121r9]. These elements provide metadata that allows the 
  categorization of a service and enables discovery and evaluation of the provided service."

  ## Required Elements

  - `title` - Brief narrative name or label for the service
  - `service_type` - Service type identifier, shall be "WMTS" 
  - `service_type_version` - Version of the service type, shall be "1.0.0"

  ## Optional Elements

  - `abstract` - Brief narrative description of the service
  - `keywords` - List of descriptive keywords about the service  
  - `profile` - Application profiles that the service conforms to
  - `fees` - Fees and terms for retrieving data from or otherwise using the service
  - `access_constraints` - Access constraints applied to assure the protection of privacy or intellectual property
  """

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
