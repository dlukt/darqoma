defmodule Pleroma.Repo.Migrations.UsersAddOutboxes do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add_if_not_exists(:outbox, :text)
    end

    execute("update users set outbox = replace(inbox, 'inbox', 'outbox')")
  end

  def down do
    alter table(:users) do
      remove_if_exists(:outbox, :text)
    end
  end
end
