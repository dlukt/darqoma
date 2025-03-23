# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Metadata.Providers.ApUrlTest do
  use Pleroma.DataCase, async: true
  import Pleroma.Factory
  alias Pleroma.Web.Metadata.Providers.ApUrl

  test "it renders a link to the post" do
    user = insert(:user)

    note =
      insert(:note, %{
        "actor" => user.ap_id,
        "tag" => [],
        "id" => "https://akkoma.example/objects/whatever",
        "content" => "Me when i’m in the write test data competition but my opponent is akkoma"
      })

    assert ApUrl.build_tags(%{object: note, url: note.data["id"], user: user}) == [
             {:link,
              [
                rel: "alternate",
                type: "application/activity+json",
                href: note.data["id"]
              ], []}
           ]
  end

  test "it renders a link to the user" do
    user = insert(:user)

    assert ApUrl.build_tags(%{user: user}) == [
             {:link, [rel: "alternate", type: "application/activity+json", href: user.ap_id], []}
           ]
  end
end
