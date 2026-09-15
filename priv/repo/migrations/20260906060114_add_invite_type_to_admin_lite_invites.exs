defmodule Home.Repo.Migrations.AddInviteTypeToAdminLiteInvites do
  use Ecto.Migration

  def change do
    alter table(:admin_lite_invites) do
      add :invite_type, :string
    end
  end
end
