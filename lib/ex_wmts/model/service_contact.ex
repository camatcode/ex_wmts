defmodule ExWMTS.ServiceContact do
  @moduledoc false

  import SweetXml

  alias __MODULE__, as: ServiceContact
  alias ExWMTS.ContactInfo

  defstruct [:individual_name, :position_name, :contact_info, :role]

  def build(nil), do: nil

  def build(contact_node) do
    make_service_contact(contact_node)
    |> then(&struct(ServiceContact, &1))
  end

  defp make_service_contact(contact_node) do
    %{
      individual_name: contact_node |> xpath(~x"./*[local-name()='IndividualName']/text()"s),
      position_name: contact_node |> xpath(~x"./*[local-name()='PositionName']/text()"s),
      contact_info: contact_node |> xpath(~x"./*[local-name()='ContactInfo']") |> ContactInfo.build(),
      role: contact_node |> xpath(~x"./*[local-name()='Role']/text()"s)
    }
  end
end
