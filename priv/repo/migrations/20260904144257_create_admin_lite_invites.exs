defmodule Home.Repo.Migrations.CreateVerificationRequests do
  use Ecto.Migration

  def change do
    create table(:verification_requests) do
      add :names, :string, null: false
      add :email, :string, null: false
      add :phone, :string, null: false
      add :status, :string, default: "pending", null: false

      timestamps()
    end

    create index(:verification_requests, [:email])
    create index(:verification_requests, [:status])
  end
end
