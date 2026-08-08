# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.EctoType.Config.BinaryValue do
  use Ecto.Type

  # Keep atoms from configuration keys that were supported by older releases
  # available before ConfigDB values are decoded. `binary_to_term/2` with the
  # `:safe` option intentionally refuses to create atoms, so a persisted legacy
  # key would otherwise prevent the application from starting.
  @legacy_config_atoms [:soapbox_fe]

  @doc false
  def legacy_config_atoms, do: @legacy_config_atoms

  def type, do: :term

  def cast(value) when is_binary(value) do
    if String.valid?(value) do
      {:ok, value}
    else
      {:ok, safe_binary_to_term(value)}
    end
  end

  def cast(value), do: {:ok, value}

  def load(value) when is_binary(value) do
    {:ok, safe_binary_to_term(value)}
  end

  def dump(value) do
    {:ok, :erlang.term_to_binary(value)}
  end

  defp safe_binary_to_term(value) do
    _ = legacy_config_atoms()
    :erlang.binary_to_term(value, [:safe])
  end
end
