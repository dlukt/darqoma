defmodule Phoenix.Transports.WebSocket.RawTest do
  use ExUnit.Case, async: true

  alias Phoenix.Transports.WebSocket.Raw

  describe "default_config/0" do
    test "returns the expected configuration" do
      assert Raw.default_config() == [
               timeout: 60_000,
               transport_log: false,
               cowboy: Phoenix.Endpoint.CowboyWebSocket
             ]
    end
  end
end
