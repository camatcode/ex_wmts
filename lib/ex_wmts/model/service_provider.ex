defmodule ExWMTS.ServiceProvider do
  @moduledoc false

  import ExWMTS.XPathHelpers
  import SweetXml

  alias __MODULE__, as: ServiceProvider
  alias ExWMTS.ServiceContact

  defstruct [:provider_name, :provider_site, :service_contact]

  def build(nil), do: nil

  def build(m) do
    provider = make_service_provider(m)
    if provider, do: struct(ServiceProvider, provider)
  end

  defp make_service_provider(provider_node) do
    %{
      provider_name: provider_node |> xpath(text("ProviderName")),
      provider_site: provider_node |> xpath(~x"./*[local-name()='ProviderSite']/@xlink:href"s),
      service_contact: provider_node |> xpath(element("ServiceContact")) |> ServiceContact.build()
    }
  end
end
