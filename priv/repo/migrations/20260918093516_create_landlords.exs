defmodule Home.Repo.Migrations.CreateLandlords do
  use Ecto.Migration

  def change do
    create table(:landlords) do
      # Step 1: Personal Details
      add :entity_type, :string, default: "individual", null: false
      add :names, :string, null: false
      add :email, :string, null: false
      add :phone, :string, null: false
      add :whatsapp_phone, :string
      add :residence_location, :string

      # Relationships
      add :user_id, references(:users, on_delete: :delete_all)
      add :verification_request_id, references(:verification_requests, on_delete: :nilify_all)

      timestamps()
    end

    create index(:landlords, [:user_id])
    create index(:landlords, [:verification_request_id])
    create unique_index(:landlords, [:email])
  end
end
