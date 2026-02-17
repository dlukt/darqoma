# Pleroma: A lightweight social networking server
# Copyright © 2017-2024 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.PleromaAPI.BookmarkFolderView do
  use Pleroma.Web, :view

  alias Pleroma.BookmarkFolder
  alias Pleroma.Emoji
  alias Pleroma.Web.Endpoint

  def render("show.json", %{folder: %BookmarkFolder{} = folder}) do
    {emoji, emoji_url} = get_emoji(folder.emoji)

    %{
      id: folder.id |> to_string(),
      name: folder.name,
      emoji: emoji,
      emoji_url: emoji_url
    }
  end

  def render("index.json", %{folders: folders} = opts) do
    render_many(folders, __MODULE__, "show.json", Map.delete(opts, :folders))
  end

  defp get_emoji(nil), do: {nil, nil}

  defp get_emoji(emoji) do
    if Emoji.is_unicode_emoji?(emoji) do
      {emoji, nil}
    else
      case Emoji.get(emoji) do
        nil -> {nil, nil}
        emoji_data -> {emoji, Endpoint.url() |> URI.merge(emoji_data.file) |> to_string()}
      end
    end
  end
end
