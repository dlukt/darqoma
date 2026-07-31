# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Conversation.Participation.RecipientShip do
  use Ecto.Schema

  alias Pleroma.Conversation.Participation
  alias Pleroma.Repo
  alias Pleroma.User

  import Ecto.Changeset

  schema "conversation_participation_recipient_ships" do
    belongs_to(:user, User, type: FlakeId.Ecto.CompatType)
    belongs_to(:participation, Participation)
  end

  def creation_cng(struct, params) do
    struct
    |> cast(params, [:user_id, :participation_id])
    |> validate_required([:user_id, :participation_id])
  end

  def create(%User{} = user, participation), do: create([user], participation)

  def create([], _participation), do: :ok

  def create(users, participation) do
    records =
      Enum.map(users, fn user ->
        %{user_id: user.id, participation_id: participation.id}
      end)

    Repo.insert_all(__MODULE__, records)

    :ok
  end
end
