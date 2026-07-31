defmodule Pleroma.MapsTest do
  use ExUnit.Case, async: true
  alias Pleroma.Maps

  describe "put_if_present/3" do
    test "puts value in map if key and value are not nil" do
      assert Maps.put_if_present(%{}, :a, 1) == %{a: 1}
    end

    test "does not put value if key is nil" do
      assert Maps.put_if_present(%{}, nil, 1) == %{}
    end

    test "does not put value if value is nil" do
      assert Maps.put_if_present(%{}, :a, nil) == %{}
    end
  end

  describe "put_if_present/4" do
    test "puts value after applying value_function" do
      assert Maps.put_if_present(%{}, :a, 1, fn v -> {:ok, v * 2} end) == %{a: 2}
    end

    test "does not put value if value_function does not return {:ok, new_value}" do
      assert Maps.put_if_present(%{}, :a, 1, fn _ -> :error end) == %{}
    end
  end

  describe "safe_put_in/3" do
    test "puts value in nested map" do
      assert Maps.safe_put_in(%{a: %{b: 1}}, [:a, :b], 2) == %{a: %{b: 2}}
    end

    test "returns original map if path does not exist" do
      assert Maps.safe_put_in(%{a: %{b: 1}}, [:a, :c, :d], 2) == %{a: %{b: 1}}
    end

    test "returns original map if key path is invalid" do
      assert Maps.safe_put_in(%{a: 1}, [:a, :b], 2) == %{a: 1}
    end
  end
end
