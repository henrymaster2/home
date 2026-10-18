defmodule Home.Repo.Migrations.AddRegistrationDataToLandlords do
  use Ecto.Migration

  def change do
    alter table(:landlords) do
      add :registration_data, :map, null: false, default: %{}
    end
  end
end
