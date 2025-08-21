defmodule ExWMTS.HTTP do
  @moduledoc false

  import SweetXml

  alias __MODULE__, as: HTTP
  alias ExWMTS.HTTPMethod

  defstruct [:get, :post]

  def build(nil), do: nil

  def build(http_node) do
    http_data =
      http_node
      |> xpath(~x".",
        get: ~x"./*[local-name()='Get']"el,
        post: ~x"./*[local-name()='Post']"el
      )

    get_methods = HTTPMethod.build(http_data.get)
    post_methods = HTTPMethod.build(http_data.post)

    %HTTP{
      get: get_methods,
      post: post_methods
    }
  end
end
