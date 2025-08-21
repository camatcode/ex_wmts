defmodule ExWMTS.HTTPMethod do
  @moduledoc false

  import ExWMTS.Model.Common
  import SweetXml

  alias __MODULE__, as: HTTPMethod
  alias ExWMTS.Constraint

  defstruct [:href, :constraints]

  def build(nil), do: nil
  def build([]), do: nil

  def build(method_nodes) when is_list(method_nodes), do: Enum.map(method_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(method_node) do
    method_data =
      method_node
      |> xpath(~x".",
        href: ~x"./@*[local-name()='href']"s,
        constraints: ~x"./*[local-name()='Constraint']"el
      )

    href = normalize_text(method_data.href, nil)

    if href do
      constraints = Constraint.build(method_data.constraints)

      %HTTPMethod{
        href: href,
        constraints: constraints
      }
    end
  end
end
