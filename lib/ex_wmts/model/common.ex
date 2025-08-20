defmodule ExWMTS.Model.Common do
  @moduledoc false

  def normalize_text(text, fallback \\ nil)
  def normalize_text(nil, fallback), do: fallback
  def normalize_text("", fallback), do: fallback
  def normalize_text(text, _fallback) when is_binary(text), do: String.trim(text)

  def parse_float(nil), do: 0.0
  def parse_float(""), do: 0.0

  def parse_float(str) when is_binary(str) do
    str
    |> String.trim()
    |> Float.parse()
    |> case do
      {float, _} -> float
      :error -> 0.0
    end
  end

  def parse_integer(nil, default), do: default
  def parse_integer("", default), do: default

  def parse_integer(str, default) when is_binary(str) do
    str
    |> String.trim()
    |> Integer.parse()
    |> case do
      {int, _} -> int
      :error -> default
    end
  end
end
