defmodule Home.Repo.Migrations.CreateUserIdentities do
  use Ecto.Migration

  def change do
    create table(:user_identities) do
      add :provider, :string, null: false
      add :provider_user_id, :string, null: false

      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_identities, [:provider, :provider_user_id])
    create index(:user_identities, [:user_id])
  end
end
