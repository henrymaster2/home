defmodule Home.Repo.Migrations.CreateAdminLiteInvites do
  use Ecto.Migration

  def change do
    create table(:admin_lite_invites) do
      add :email, :string, null: false
      add :token, :string, null: false
      add :used_at, :naive_datetime
      add :expires_at, :naive_datetime, null: false
      add :created_by_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:admin_lite_invites, [:email])
    create unique_index(:admin_lite_invites, [:token])
    create index(:admin_lite_invites, [:created_by_id])
  end
end
