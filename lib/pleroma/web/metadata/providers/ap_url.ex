# Akkoma: Magically expressive social media
# Copyright © 2025 Akkoma Authors <https://akkoma.dev/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Metadata.Providers.ApUrl do
  alias Pleroma.Web.Metadata.Providers.Provider

  use Pleroma.Web, :verified_routes

  @behaviour Provider

  @impl Provider
  def build_tags(%{url: url}) do
    [
      {:link,
       [
         rel: "alternate",
         type: "application/activity+json",
         href: url
       ], []}
    ]
  end

  @impl Provider
  def build_tags(%{user: user}) do
    [
      {:link,
       [
         rel: "alternate",
         type: "application/activity+json",
         href: user.uri || user.ap_id
       ], []}
    ]
  end
end
