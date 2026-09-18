defmodule Home.Repo.Migrations.AddIdentityFieldsToLandlords do
  use Ecto.Migration

  def change do
    alter table(:landlords) do
      add :id_type, :string, default: "National ID"
      add :id_number, :string
      add :kra_pin, :string
      add :id_front_url, :string
      add :id_back_url, :string
    end
  end
end
