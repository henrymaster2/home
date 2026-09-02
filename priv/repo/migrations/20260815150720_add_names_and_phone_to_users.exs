defmodule Home.Repo.Migrations.AddNamesAndPhoneToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :names, :string
      add :phone, :string
    end
  end
end
