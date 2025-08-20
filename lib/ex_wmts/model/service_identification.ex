defmodule ExWMTS.ServiceIdentification do
  @moduledoc false

  import SweetXml

  alias __MODULE__, as: ServiceIdentification

  defstruct title: "Unknown Service", abstract: nil, service_type: "WMTS", service_type_version: "1.0.0"

  def build(m) when is_map(m) do
    m
    |> then(&struct(ServiceIdentification, &1))
  end

  def build(nil), do: build(%{})

  def build(service_node) do
    %{
      title: service_node |> xpath(~x"./*[local-name()='Title']/text()"s),
      abstract: service_node |> xpath(~x"./*[local-name()='Abstract']/text()"s),
      service_type: service_node |> xpath(~x"./*[local-name()='ServiceType']/text()"s),
      service_type_version: service_node |> xpath(~x"./*[local-name()='ServiceTypeVersion']/text()"s)
    }
    |> build()
  end
end
