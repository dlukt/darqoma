# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.MRF.ObjectAgePolicy do
  alias Pleroma.Config
  alias Pleroma.User

  require Pleroma.Constants

  @moduledoc "Filter activities depending on their age"
  @behaviour Pleroma.Web.ActivityPub.MRF.Policy

  defp update_to_cc(message, to, cc) do
    message =
      message
      |> Map.put("to", to)
      |> Map.put("cc", cc)

    if Map.has_key?(message, "object") do
      message
      |> Kernel.put_in(["object", "to"], to)
      |> Kernel.put_in(["object", "cc"], cc)
    else
      message
    end
  end

  defp check_date(%{"object" => %{"published" => _} = object} = activity) do
    with {:ok, object} <- check_date(object) do
      activity = activity |> Map.put("object", object)
      {:ok, activity}
    else
      e -> e
    end
  end

  defp check_date(%{"published" => published} = object) do
    with %DateTime{} = now <- DateTime.utc_now(),
         {:ok, %DateTime{} = then, _} <- DateTime.from_iso8601(published),
         max_ttl <- Config.get([:mrf_object_age, :threshold]),
         {:ttl, false} <- {:ttl, DateTime.diff(now, then) > max_ttl} do
      {:ok, object}
    else
      {:ttl, true} ->
        {:reject, nil}

      e ->
        {:error, e}
    end
  end

  defp check_reject(message, actions) do
    if :reject in actions do
      {:reject, "[ObjectAgePolicy]"}
    else
      {:ok, message}
    end
  end

  defp check_delist(message, actions) do
    if :delist in actions do
      with %User{} = user <- User.get_cached_by_ap_id(message["actor"]) do
        to =
          List.delete(message["to"] || [], Pleroma.Constants.as_public()) ++
            [user.follower_address]

        cc =
          List.delete(message["cc"] || [], user.follower_address) ++
            [Pleroma.Constants.as_public()]

        message =
          message
          |> update_to_cc(to, cc)

        {:ok, message}
      else
        _e ->
          {:reject, "[ObjectAgePolicy] Unhandled error"}
      end
    else
      {:ok, message}
    end
  end

  defp check_strip_followers(message, actions) do
    if :strip_followers in actions do
      with %User{} = user <- User.get_cached_by_ap_id(message["actor"]) do
        to = List.delete(message["to"] || [], user.follower_address)
        cc = List.delete(message["cc"] || [], user.follower_address)

        message =
          message
          |> update_to_cc(to, cc)

        {:ok, message}
      else
        _e ->
          {:reject, "[ObjectAgePolicy] Unhandled error"}
      end
    else
      {:ok, message}
    end
  end

  defp maybe_check_reject(message, _actions, false) do
    {:ok, message}
  end

  defp maybe_check_reject(message, actions, true) do
    check_reject(message, actions)
  end

  defp check(message, allow_reject) do
    with actions <- Config.get([:mrf_object_age, :actions]),
         {:reject, _} <- check_date(message),
         {:ok, message} <- maybe_check_reject(message, actions, allow_reject),
         {:ok, message} <- check_delist(message, actions),
         {:ok, message} <- check_strip_followers(message, actions) do
      {:ok, message}
    else
      # check_date() is allowed to short-circuit the pipeline
      e -> e
    end
  end

  @impl true
  def filter(%{"type" => "Create", "object" => %{"published" => _}} = message) do
    check(message, true)
  end

  @impl true
  def filter(%{"type" => type, "published" => _} = message)
      when type in Pleroma.Constants.object_types() do
    check(message, false)
  end

  @impl true
  def filter(message), do: {:ok, message}

  @impl true
  def describe do
    mrf_object_age =
      Config.get(:mrf_object_age)
      |> Enum.into(%{})

    {:ok, %{mrf_object_age: mrf_object_age}}
  end

  @impl true
  def config_description do
    %{
      key: :mrf_object_age,
      related_policy: "Pleroma.Web.ActivityPub.MRF.ObjectAgePolicy",
      label: "MRF Object Age",
      description:
        "Rejects or delists posts based on their timestamp deviance from your server's clock.",
      children: [
        %{
          key: :threshold,
          type: :integer,
          description: "Required age (in seconds) of a post before actions are taken.",
          suggestions: [172_800]
        },
        %{
          key: :actions,
          type: {:list, :atom},
          description:
            "A list of actions to apply to the post. `:delist` removes the post from public timelines; " <>
              "`:strip_followers` removes followers from the ActivityPub recipient list ensuring they won't be delivered to home timelines; " <>
              "`:reject` rejects the message entirely",
          suggestions: [:delist, :strip_followers, :reject]
        }
      ]
    }
  end
end
