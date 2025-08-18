defmodule ExWMTS do
  @moduledoc """
  ExWMTS provides an Elixir client for accessing WMTS (Web Map Tile Service) endpoints.

  WMTS is an OGC standard for serving pre-rendered map tiles over HTTP. This library
  allows you to fetch capabilities documents and individual tiles from WMTS-compatible
  servers.

  ## Basic Usage

  ### Fetching Capabilities

      iex> ExWMTS.get_capabilities("https://example.com/wmts") 
      {:ok, "<?xml version=\\"1.0\\"..."}

  ### Fetching Tiles

      iex> params = %{
      ...>   layer: "BlueMarble_ShadedRelief_Bathymetry",
      ...>   style: "default",
      ...>   tile_matrix_set: "GoogleMapsCompatible", 
      ...>   tile_matrix: "5",
      ...>   tile_row: 10,
      ...>   tile_col: 15,
      ...>   format: "image/jpeg"
      ...> }
      iex> ExWMTS.get_tile("https://example.com/wmts", params)
      {:ok, <<255, 216, 255, 224, 0, 16, 74, 70, 73, 70, 0, 1, 1, 1, 0, 72>>}

  ## Error Handling

  All functions return tagged tuples in the format `{:ok, result}` or `{:error, reason}`.
  Common errors include:

  - `{:error, {:missing_params, [keys]}}` - Required parameters are missing
  - `{:error, :invalid_params}` - Parameters are invalid (e.g., negative coordinates)
  - `{:error, {:http_error, status}}` - HTTP request failed with given status
  - `{:error, {:request_failed, reason}}` - Network or other request failure
  """

  alias ExWMTS.WMTSClient

  @doc """
  Fetches and parses the capabilities document from a WMTS endpoint.

  Returns structured data about available layers, tile matrix sets, and formats
  instead of raw XML. This makes it easy to programmatically discover what
  layers and configurations are available.

  ## Parameters
  - `base_url` - The base WMTS endpoint URL

  ## Examples

      iex> ExWMTS.get_capabilities("https://example.com/wmts")
      {:ok, %{
        service_identification: %{title: "My WMTS Service"},
        layers: [
          %{
            identifier: "layer1", 
            title: "Layer 1",
            formats: ["image/png", "image/jpeg"],
            tile_matrix_sets: ["GoogleMapsCompatible", "custom_grid"],
            styles: ["default"]
          }
        ],
        tile_matrix_sets: [
          %{
            identifier: "GoogleMapsCompatible",
            supported_crs: "EPSG:3857",
            matrices: [...]
          }
        ],
        formats: ["image/png", "image/jpeg"]
      }}

  Use the returned data to discover available layers and their supported
  configurations, then pass those to `get_tile/2`.

  """
  @spec get_capabilities(String.t()) :: {:ok, ExWMTS.CapabilitiesParser.capabilities()} | {:error, term()}
  def get_capabilities(base_url), do: WMTSClient.get_capabilities(base_url)

  @doc """
  Fetches the raw capabilities XML from a WMTS endpoint.

  Most users should use `get_capabilities/1` instead, which returns structured data.
  Use this only if you need the raw XML for custom parsing.

  ## Parameters
  - `base_url` - The base WMTS endpoint URL

  ## Examples

      iex> ExWMTS.get_capabilities_xml("https://example.com/wmts")
      {:ok, "<?xml version=\\"1.0\\"..."}

  """
  @spec get_capabilities_xml(String.t()) :: {:ok, String.t()} | {:error, term()}
  def get_capabilities_xml(base_url), do: WMTSClient.get_capabilities_xml(base_url)

  @doc """
  Fetches a specific tile from a WMTS endpoint.

  ## Parameters
  - `base_url` - The base WMTS endpoint URL
  - `params` - Map containing tile parameters:
    - `:layer` - Layer identifier (required)
    - `:style` - Style identifier, often "default" (required)
    - `:tile_matrix_set` - Tile matrix set identifier (required)
    - `:tile_matrix` - Zoom level identifier (required)
    - `:tile_row` - Row coordinate of the tile (required, non-negative integer)
    - `:tile_col` - Column coordinate of the tile (required, non-negative integer)
    - `:format` - Image format like "image/png" or "image/jpeg" (required)

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
      iex> ExWMTS.get_tile("https://example.com/wmts", params)
      {:ok, <<255, 216, 255, 224, 0, 16, 74, 70, 73, 70, 0, 1, 1, 1, 0, 72>>}

  ## Common Tile Matrix Sets
  - `"GoogleMapsCompatible"` - Web Mercator projection compatible with Google Maps
  - `"2km"`, `"1km"`, `"500m"`, `"250m"` - Fixed resolution matrices

  ## Coordinate System
  WMTS uses a tile-based coordinate system where:
  - `tile_matrix` represents the zoom level (0 = most zoomed out)
  - `tile_row` and `tile_col` are the tile coordinates at that zoom level
  - Origin is typically at the top-left corner
  """
  @spec get_tile(String.t(), map()) :: {:ok, binary()} | {:error, term()}
  def get_tile(base_url, params), do: WMTSClient.get_tile(base_url, params)
end
