defmodule ExWMTS.Constraint do
  @moduledoc false

  import ExWMTS.Model.Common
  import SweetXml

  alias __MODULE__, as: Constraint

  defstruct [:name, :allowed_values]

  def build(nil), do: nil
  def build([]), do: nil

  def build(constraint_nodes) when is_list(constraint_nodes),
    do: Enum.map(constraint_nodes, &build/1) |> Enum.reject(&is_nil/1)

  def build(constraint_node) do
    constraint_data =
      constraint_node
      |> xpath(~x".",
        name: ~x"./@name"s,
        allowed_values: ~x"./*[local-name()='AllowedValues']/*[local-name()='Value']/text()"sl
      )

    name = normalize_text(constraint_data.name, nil)

    if name do
      allowed_values =
        constraint_data.allowed_values
        |> Enum.map(&normalize_text(&1, nil))
        |> Enum.reject(&is_nil/1)

      %Constraint{
        name: name,
        allowed_values: allowed_values
      }
    end
  end
end
