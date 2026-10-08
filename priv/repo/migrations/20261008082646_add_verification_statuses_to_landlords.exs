defmodule Home.Repo.Migrations.AddVerificationStatusesToLandlords do
  use Ecto.Migration

  def change do
    alter table(:landlords) do
      add :personal_details_status, :string, default: "pending", null: false
      add :identity_status, :string, default: "pending", null: false
      add :property_status, :string, default: "pending", null: false
      add :billing_status, :string, default: "pending", null: false
      add :verification_status, :string, default: "pending", null: false
      add :admin_notes, :map, default: %{}
    end
  end
end
