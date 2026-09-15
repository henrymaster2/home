defmodule Home.Repo.Migrations.CreateVerificationRequests do
  use Ecto.Migration

  def change do
    create table(:verification_requests) do
      add :names, :string
      add :email, :string
      add :phone, :string
      add :status, :string
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:verification_requests, [:user_id])
  end
end
