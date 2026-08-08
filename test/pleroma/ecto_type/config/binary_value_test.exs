# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.EctoType.Config.BinaryValueTest do
  use ExUnit.Case, async: true

  alias Pleroma.EctoType.Config.BinaryValue

  test "loads persisted configuration containing a supported legacy atom" do
    encoded = <<131, 119, 10, "soapbox_fe">>

    assert {:ok, value} = BinaryValue.load(encoded)
    assert Atom.to_string(value) == "soapbox_fe"
  end

  test "does not create unknown atoms while loading persisted configuration" do
    atom_name = "unknown_config_atom_#{System.unique_integer([:positive])}"
    encoded = <<131, 119, byte_size(atom_name), atom_name::binary>>

    assert_raise ArgumentError, fn -> BinaryValue.load(encoded) end
  end
end
