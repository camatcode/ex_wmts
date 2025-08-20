defmodule ExWMTS.ServiceIdentification do
  @moduledoc false

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
      title: service_node |> xpath(~x"./*[local-name()='Title']/text()"s),
      abstract: service_node |> xpath(~x"./*[local-name()='Abstract']/text()"s),
      keywords: service_node |> xpath(~x"./*[local-name()='Keywords']/*[local-name()='Keyword']/text()"sl),
      service_type: service_node |> xpath(~x"./*[local-name()='ServiceType']/text()"s),
      service_type_version: service_node |> xpath(~x"./*[local-name()='ServiceTypeVersion']/text()"s),
      profile: service_node |> xpath(~x"./*[local-name()='Profile']/text()"sl),
      fees: service_node |> xpath(~x"./*[local-name()='Fees']/text()"s),
      access_constraints: service_node |> xpath(~x"./*[local-name()='AccessConstraints']/text()"s)
    }
    |> then(&struct(ServiceIdentification, &1))
  end
end
