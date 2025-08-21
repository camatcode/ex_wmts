defmodule ExWMTS.WMTSClient do
  @moduledoc """
  Client for interacting with WMTS (Web Map Tile Service) endpoints.

  Provides functions to fetch capabilities and tiles from WMTS-compatible servers.
  """

  alias ExWMTS.CapabilitiesParser

  @type tile_params :: %{
          layer: String.t(),
          style: String.t(),
          tile_matrix_set: String.t(),
          tile_matrix: String.t(),
          tile_row: non_neg_integer(),
          tile_col: non_neg_integer(),
          format: String.t()
        }

  @type wmts_error :: {:error, term()}

  @doc """
  Fetches and parses the capabilities document from a WMTS endpoint.

  Returns structured data about available layers, tile matrix sets, and formats
  instead of raw XML.

  ## Parameters
  - `base_url` - The base WMTS endpoint URL

  ## Examples  

  """
  @spec get_capabilities(String.t()) :: {:ok, CapabilitiesParser.capabilities()} | wmts_error()
  def get_capabilities(base_url) when is_bitstring(base_url) do
    with {:ok, body} <- get_capabilities_xml(base_url) do
      CapabilitiesParser.parse(body)
    end
  end

  @doc """
  Fetches the raw capabilities XML from a WMTS endpoint.

  Use this if you need to parse the XML yourself or want the raw response.
  Most users should use `get_capabilities/1` instead.

  ## Parameters
  - `base_url` - The base WMTS endpoint URL

  ## Examples
  """
  @spec get_capabilities_xml(String.t()) :: {:ok, String.t()} | wmts_error()
  def get_capabilities_xml(base_url) when is_bitstring(base_url) do
    url = build_capabilities_url(base_url)

    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:error, other} ->
        {:error, other}
    end
  end

  @doc """
  Fetches a specific tile from a WMTS endpoint.

  ## Parameters
  - `base_url` - The base WMTS endpoint URL (or capabilities struct for ResourceURL support)
  - `params` - Map containing tile parameters:
    - `:layer` - Layer identifier
    - `:style` - Style identifier (often "default")
    - `:tile_matrix_set` - Tile matrix set identifier (e.g., "GoogleMapsCompatible")
    - `:tile_matrix` - Zoom level identifier
    - `:tile_row` - Row coordinate of the tile
    - `:tile_col` - Column coordinate of the tile  
    - `:format` - Image format (e.g., "image/png", "image/jpeg")

  ## Examples

      iex> params = %{
      ...>   layer: "BlueMarble_ShadedRelief_Bathymetry",
      ...>   style: "default", 
      ...>   tile_matrix_set: "GoogleMapsCompatible",
      ...>   tile_matrix: "5",
      ...>   tile_row: 10,
      ...>   tile_col: 15,
      ...>   format: "image/jpeg"
      ...> }
      iex> ExWMTS.WMTSClient.get_tile("https://example.com/wmts", params)
      {:ok, <<255, 216, 255, 224, 0, 16, 74, 70, 73, 70, 0, 1, 1, 1, 0, 72, 0, 72, 0, 0, 255>>}

  ## ResourceURL Support

  For better WMTS compliance, you can pass the capabilities struct instead of base_url
  to automatically use ResourceURL templates when available:

      iex> {:ok, capabilities} = ExWMTS.WMTSClient.get_capabilities(base_url)
      iex> ExWMTS.WMTSClient.get_tile(capabilities, params)
      {:ok, binary_tile_data}

  """
  @spec get_tile(String.t() | CapabilitiesParser.capabilities(), tile_params()) :: {:ok, binary()} | wmts_error()
  def get_tile(base_url_or_capabilities, params) when is_map(params) do
    with {:ok, validated_params} <- validate_tile_params(params),
         {:ok, url} <- build_tile_url(base_url_or_capabilities, validated_params) do
      case Req.get(url) do
        {:ok, %Req.Response{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %Req.Response{status: status, body: error_body}} ->
          {:error, {:http_error, status, error_body, url}}

        {:error, reason} ->
          {:error, {:request_failed, reason}}
      end
    end
  end

  # Private functions

  defp build_capabilities_url(base_url) do
    base_url = String.trim(base_url)

    query_string =
      [
        {"SERVICE", "WMTS"},
        {"REQUEST", "GetCapabilities"},
        {"VERSION", "1.0.0"}
      ]
      |> URI.encode_query()

    separator = if String.ends_with?(base_url, "?"), do: "&", else: "?"

    "#{base_url}#{separator}#{query_string}"
  end

  defp build_tile_url(base_url, params) when is_bitstring(base_url) do
    # Legacy KVP encoding when just base URL is provided
    {:ok, build_kvp_tile_url(base_url, params)}
  end

  defp build_tile_url(capabilities, params) when is_map(capabilities) do
    # Try to find ResourceURL template for this layer and format
    case find_resource_url_template(capabilities, params) do
      {:ok, template} ->
        {:ok, build_restful_tile_url(template, params)}

      :not_found ->
        # Fallback to KVP encoding - we need a base URL for this
        # Try to extract from operations metadata
        case extract_base_url_from_capabilities(capabilities) do
          {:ok, base_url} -> {:ok, build_kvp_tile_url(base_url, params)}
          :not_found -> {:error, :no_tile_url_available}
        end
    end
  end

  defp build_kvp_tile_url(base_url, params) do
    query_string =
      [
        {"SERVICE", "WMTS"},
        {"REQUEST", "GetTile"},
        {"VERSION", "1.0.0"},
        {"LAYER", params.layer},
        {"STYLE", params.style},
        {"TILEMATRIXSET", params.tile_matrix_set},
        {"TILEMATRIX", params.tile_matrix},
        {"TILEROW", to_string(params.tile_row)},
        {"TILECOL", to_string(params.tile_col)},
        {"FORMAT", params.format}
      ]
      |> URI.encode_query()

    separator = if String.ends_with?(base_url, "?"), do: "&", else: "?"

    "#{base_url}#{separator}#{query_string}"
  end

  defp build_restful_tile_url(template, params) do
    url =
      template
      |> String.replace("{TileMatrixSet}", params.tile_matrix_set)
      |> String.replace("{TileMatrix}", params.tile_matrix)
      |> String.replace("{TileRow}", to_string(params.tile_row))
      |> String.replace("{TileCol}", to_string(params.tile_col))
      |> String.replace("{Style}", params.style)
      # Some services use lowercase
      |> String.replace("{style}", params.style)
      # Some services use lowercase
      |> String.replace("{layer}", params.layer)

    url
  end

  defp find_resource_url_template(capabilities, params) do
    # Find the layer matching the requested layer identifier
    layer =
      Enum.find(capabilities.layers, fn layer ->
        layer.identifier == params.layer
      end)

    if layer && layer.resource_urls do
      # Find ResourceURL with matching format and type "tile"
      matching_resources =
        Enum.filter(layer.resource_urls, fn resource ->
          resource.resource_type == "tile" && resource.format == params.format
        end)

      # Prefer templates without {Time} variable for now
      preferred_template =
        Enum.find(matching_resources, fn resource ->
          resource.template && !String.contains?(resource.template, "{Time}")
        end)

      template = preferred_template || hd(matching_resources)

      if template && template.template do
        {:ok, template.template}
      else
        :not_found
      end
    else
      :not_found
    end
  end

  defp extract_base_url_from_capabilities(capabilities) do
    # Try to find GetTile operation with KVP binding
    if capabilities.operations_metadata && capabilities.operations_metadata.operations do
      get_tile_op =
        Enum.find(capabilities.operations_metadata.operations, fn op ->
          op.name == "GetTile"
        end)

      if get_tile_op && get_tile_op.dcp && get_tile_op.dcp.http do
        # Look for GET method with KVP constraint
        get_method = get_tile_op.dcp.http.get

        if get_method && get_method.href do
          {:ok, get_method.href}
        else
          :not_found
        end
      else
        :not_found
      end
    else
      :not_found
    end
  end

  defp validate_tile_params(params) do
    required_keys = [:layer, :style, :tile_matrix_set, :tile_matrix, :tile_row, :tile_col, :format]

    missing_keys = Enum.filter(required_keys, fn key -> not Map.has_key?(params, key) end)

    if missing_keys == [] do
      # Validate numeric parameters
      with {:ok, tile_row} <- validate_non_negative_integer(params.tile_row),
           {:ok, tile_col} <- validate_non_negative_integer(params.tile_col) do
        validated_params = %{params | tile_row: tile_row, tile_col: tile_col}
        {:ok, validated_params}
      else
        {:error, _} -> {:error, :invalid_params}
      end
    else
      {:error, {:missing_params, missing_keys}}
    end
  end

  defp validate_non_negative_integer(value) when is_integer(value) and value >= 0, do: {:ok, value}

  defp validate_non_negative_integer(value) when is_bitstring(value) do
    case Integer.parse(value) do
      {int, ""} when int >= 0 -> {:ok, int}
      _ -> {:error, :invalid_integer}
    end
  end

  defp validate_non_negative_integer(_), do: {:error, :invalid_integer}
end
