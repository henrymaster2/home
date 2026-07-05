defmodule Home.Repo.Migrations.CreateProperties do
  use Ecto.Migration

  def change do
    create table(:properties) do
      add :title, :string
      add :location, :string
      add :night_price, :integer
      add :day_price, :integer
      add :tier, :string
      add :wifi, :boolean, default: false, null: false
      add :tv, :boolean, default: false, null: false
      add :music_system, :boolean, default: false, null: false
      add :status, :string
      add :unavailable_until, :date
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:properties, [:user_id])
  end
end
