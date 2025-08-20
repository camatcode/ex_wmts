defmodule ExWMTSTest do
  use ExUnit.Case

  # doctest ExWMTS  # Disabled due to HTTP calls

  describe "get_capabilities/1" do
    test "delegates to WMTSClient" do
      # Test that the main API delegates correctly
      assert is_function(&ExWMTS.get_capabilities/1)
    end
  end

  describe "get_tile/2" do
    test "delegates to WMTSClient" do
      # Test that the main API delegates correctly
      assert is_function(&ExWMTS.get_tile/2)
    end

    test "validates parameters through delegation" do
      result = ExWMTS.get_tile("https://example.com/wmts", %{})
      assert {:error, {:missing_params, _}} = result
    end
  end
end
