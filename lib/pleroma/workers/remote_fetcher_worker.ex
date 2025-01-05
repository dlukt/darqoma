# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Workers.RemoteFetcherWorker do
  alias Pleroma.Object.Fetcher
  alias Pleroma.Object
  alias Pleroma.Web.ActivityPub.ActivityPub

  use Pleroma.Workers.WorkerHelper,
    queue: "remote_fetcher",
    unique: [period: 300, states: Oban.Job.states(), keys: [:op, :id]]

  @impl Oban.Worker

  def perform(%Job{args: %{"op" => "fetch_outbox", "id" => address}}) do
    with {:ok, outbox} <- ActivityPub.fetch_and_prepare_collection_from_ap_id(address) do
      Enum.each(outbox, fn {ap_id, _} ->
        if is_nil(Object.get_cached_by_ap_id(ap_id)) do
          Fetcher.fetch_object_from_id(ap_id, depth: 1)
        end
      end)

      :ok
    else
      e -> {:error, e}
    end
  end

  def perform(%Job{args: %{"op" => "fetch_remote", "id" => id} = args}) do
    case Fetcher.fetch_object_from_id(id, depth: args["depth"]) do
      {:ok, _object} ->
        :ok

      {:error, :forbidden} ->
        {:discard, :forbidden}

      {:error, :not_found} ->
        {:discard, :not_found}

      {:error, :allowed_depth} ->
        {:discard, :allowed_depth}

      {:error, :invalid_uri_scheme} ->
        {:discard, :invalid_uri_scheme}

      {:error, :local_resource} ->
        {:discard, :local_resource}

      {:reject, _} ->
        {:discard, :reject}

      {:error, :id_mismatch} ->
        {:discard, :id_mismatch}

      {:error, _} = e ->
        e

      e ->
        {:error, e}
    end
  end
end
