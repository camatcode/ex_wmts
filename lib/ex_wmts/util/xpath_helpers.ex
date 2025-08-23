defmodule ExWMTS.XPathHelpers do
  @moduledoc """
  Helper functions to simplify repetitive simple xpath expressions for XML parsing.

  These helpers focus on the most common simple cases while leaving complex
  xpath expressions unchanged for clarity.
  """

  import SweetXml

  @doc """
  Extract single text value from direct child element (case insensitive).

  ## Examples
      text(node, "Identifier")  # Returns string or nil
      # Instead of: ~x"./*[local-name()='Identifier']/text()"s
  """
  def text(element_name) do
    ~x"./*[translate(local-name(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='#{String.downcase(element_name)}']/text()"s
  end

  @doc """
  Extract single child element (case insensitive).

  ## Examples  
      element("BoundingBox")  # Returns element or nil
      # Instead of: ~x"./*[local-name()='BoundingBox']"e
  """
  def element(element_name) do
    ~x"./*[translate(local-name(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='#{String.downcase(element_name)}']"e
  end

  @doc """
  Extract list of child elements (case insensitive).

  ## Examples
      element_list("Operation")  # Returns list of elements
      # Instead of: ~x"./*[local-name()='Operation']"el
  """
  def element_list(element_name) do
    ~x"./*[translate(local-name(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='#{String.downcase(element_name)}']"el
  end

  @doc """
  Extract simple attribute value (case insensitive).

  ## Examples
      attribute("format")  # Returns attribute string or nil
      # Instead of: ~x"./@format"s
      
      attribute("href", :namespaced)  # Returns namespaced attribute
      # Instead of: ~x"./@*[local-name()='href']"s
  """
  def attribute(attr_name) do
    ~x"./@*[translate(local-name(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='#{String.downcase(attr_name)}']"s
  end

  @doc """
  Extract list of text values from child elements (case insensitive).

  ## Examples
      text_list("Keyword")  # Returns list of strings
      # Instead of: ~x"./*[local-name()='Keyword']/text()"sl
  """
  def text_list(element_name) do
    ~x"./*[translate(local-name(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='#{String.downcase(element_name)}']/text()"sl
  end
end
