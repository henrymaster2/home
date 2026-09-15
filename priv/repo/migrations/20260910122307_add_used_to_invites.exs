defmodule Home.Repo.Migrations.AddUsedToAdminLiteInvites do
  use Ecto.Migration

  def change do
    alter table(:admin_lite_invites) do
      add :used, :boolean, default: false, null: false
    end
  end
end
