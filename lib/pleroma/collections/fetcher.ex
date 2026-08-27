# Akkoma: The cooler fediverse server
# Copyright © 2022- Akkoma Authors <https://akkoma.dev/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Akkoma.Collections.Fetcher do
  @moduledoc """
  Activitypub Collections fetching functions
  see: https://www.w3.org/TR/activitystreams-core/#paging
  """
  alias Pleroma.Object.Fetcher
  alias Pleroma.Config
  require Logger

  @spec fetch_collection(String.t() | map(), keyword()) :: {:ok, [Pleroma.Object.t()]} | {:error, any()}
  def fetch_collection(collection, opts \\ [])

  def fetch_collection(ap_id, opts) when is_binary(ap_id) do
    with {:ok, page} <- Fetcher.fetch_and_contain_remote_object_from_id(ap_id) do
      partial_as_success(objects_from_collection(page, opts))
    else
      e ->
        Logger.error("Could not fetch collection #{ap_id} - #{inspect(e)}")
        e
    end
  end

  def fetch_collection(%{"type" => type} = page, opts)
      when type in ["Collection", "OrderedCollection", "CollectionPage", "OrderedCollectionPage"] do
    partial_as_success(objects_from_collection(page, opts))
  end

  def fetch_collection(_, _opts) do
    {:error, :invalid_type}
  end

  defp partial_as_success({:partial, items}), do: {:ok, items}
  defp partial_as_success(res), do: res

  defp items_in_page(%{"type" => type, "orderedItems" => items})
       when is_list(items) and type in ["OrderedCollection", "OrderedCollectionPage"],
       do: items

  defp items_in_page(%{"type" => type, "items" => items})
       when is_list(items) and type in ["Collection", "CollectionPage"],
       do: items

  defp objects_from_collection(%{"type" => type, "orderedItems" => items} = page, opts)
       when is_list(items) and type in ["OrderedCollection", "OrderedCollectionPage"],
       do: maybe_next_page(page, opts, items)

  defp objects_from_collection(%{"type" => type, "items" => items} = page, opts)
       when is_list(items) and type in ["Collection", "CollectionPage"],
       do: maybe_next_page(page, opts, items)

  defp objects_from_collection(%{"type" => type, "first" => first}, opts)
       when is_binary(first) and type in ["Collection", "OrderedCollection"] do
    fetch_page_items(first, opts)
  end

  defp objects_from_collection(%{"type" => type, "first" => %{"id" => id}}, opts)
       when is_binary(id) and type in ["Collection", "OrderedCollection"] do
    fetch_page_items(id, opts)
  end

  defp objects_from_collection(_page, _opts), do: {:ok, []}

  defp fetch_page_items(id, opts, items \\ []) do
    max_objects = Keyword.get(opts, :max_collection_objects, Config.get([:activitypub, :max_collection_objects]))

    if Enum.count(items) >= max_objects do
      {:ok, Enum.take(items, max_objects)}
    else
      with {:ok, page} <- Fetcher.fetch_and_contain_remote_object_from_id(id) do
        objects = items_in_page(page)

        if Enum.count(objects) > 0 do
          maybe_next_page(page, opts, items ++ objects)
        else
          {:ok, items}
        end
      else
        {:error, :not_found} ->
          {:ok, items}

        {:error, :forbidden} ->
          {:ok, items}

        {:error, error} ->
          Logger.error("Could not fetch page #{id} - #{inspect(error)}")

          case items do
            [] -> {:error, error}
            _ -> {:partial, items}
          end
      end
    end
  end

  defp maybe_next_page(%{"next" => id}, opts, items) when is_binary(id) do
    max_objects =
      Keyword.get(opts, :max_collection_objects, Config.get([:activitypub, :max_collection_objects]))

    if Enum.count(items) >= max_objects do
      {:ok, Enum.take(items, max_objects)}
    else
      fetch_page_items(id, opts, items)
    end
  end

  defp maybe_next_page(_, opts, items) do
    max_objects = Keyword.get(opts, :max_collection_objects, Config.get([:activitypub, :max_collection_objects]))
    {:ok, Enum.take(items, max_objects)}
  end
end
