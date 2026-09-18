defmodule Home.Repo.Migrations.AddPropertyFieldsToLandlords do
  use Ecto.Migration

  def change do
    alter table(:landlords) do
      add :listing_purpose, :string, default: "renting"
      add :property_name, :string
      add :ownership_type, :string, default: "Freehold title"
      add :lr_number, :string
      add :property_location, :string
      add :total_units, :integer
      add :ownership_doc_url, :string
    end
  end
end
