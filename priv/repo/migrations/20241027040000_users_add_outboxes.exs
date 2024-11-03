defmodule Pleroma.Repo.Migrations.UsersAddOutboxes do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add_if_not_exists(:outbox, :text)
      add_if_not_exists(:last_outbox_fetch, :naive_datetime)
    end
  end

  def down do
    alter table(:users) do
      remove_if_exists(:outbox, :text)
      remove_if_exists(:last_outbox_fetch, :naive_datetime)
    end
  end
end
