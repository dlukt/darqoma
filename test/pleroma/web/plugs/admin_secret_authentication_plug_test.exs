# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Plugs.AdminSecretAuthenticationPlugTest do
  use Pleroma.Web.ConnCase, async: false
  @moduletag :mocked

  import Mock
  import Pleroma.Factory

  alias Pleroma.Web.Plugs.AdminSecretAuthenticationPlug
  alias Pleroma.Web.Plugs.OAuthScopesPlug
  alias Pleroma.Web.Plugs.PlugHelper
  alias Pleroma.Web.Plugs.RateLimiter

  @rate_limiter_opts RateLimiter.init(name: :authentication)

  test "does nothing if a user is assigned", %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> assign(:user, user)

    ret_conn =
      conn
      |> AdminSecretAuthenticationPlug.call(%{})

    assert conn == ret_conn
  end

  describe "when secret set it assigns an admin user" do
    setup do: clear_config([:admin_token])

    setup_with_mocks([{RateLimiter, [:passthrough], []}]) do
      :ok
    end

    test "with `admin_token` query parameter", %{conn: conn} do
      clear_config(:admin_token, "password123")

      conn =
        %{conn | params: %{"admin_token" => "wrong_password"}}
        |> AdminSecretAuthenticationPlug.call(%{})

      refute conn.assigns[:user]
      assert called(RateLimiter.call(conn, @rate_limiter_opts))

      conn =
        %{conn | params: %{"admin_token" => "password123"}}
        |> AdminSecretAuthenticationPlug.call(%{})

      assert conn.assigns[:user].is_admin
      assert conn.assigns[:token] == nil
      assert PlugHelper.plug_skipped?(conn, OAuthScopesPlug)
    end

    test "with `x-admin-token` HTTP header", %{conn: conn} do
      clear_config(:admin_token, "☕️")

      conn =
        conn
        |> put_req_header("x-admin-token", "🥛")
        |> AdminSecretAuthenticationPlug.call(%{})

      refute conn.assigns[:user]
      assert called(RateLimiter.call(conn, @rate_limiter_opts))

      conn =
        conn
        |> put_req_header("x-admin-token", "☕️")
        |> AdminSecretAuthenticationPlug.call(%{})

      assert conn.assigns[:user].is_admin
      assert conn.assigns[:token] == nil
      assert PlugHelper.plug_skipped?(conn, OAuthScopesPlug)
    end
  end
end
