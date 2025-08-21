defmodule ExWMTS.DCP do
  @moduledoc false

  import SweetXml

  alias __MODULE__, as: DCP
  alias ExWMTS.HTTP

  defstruct [:http]

  def build(nil), do: nil

  def build(dcp_node) do
    dcp_data =
      dcp_node
      |> xpath(~x".",
        http: ~x"./*[local-name()='HTTP']"e
      )

    http = HTTP.build(dcp_data.http)

    %DCP{
      http: http
    }
  end
end
