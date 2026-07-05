defmodule Home.Repo.Migrations.CreateBookings do
  use Ecto.Migration

  def change do
    create table(:bookings) do
      add :client_name, :string
      add :client_phone, :string
      add :check_in, :date
      add :check_out, :date
      add :total_price, :integer
      add :status, :string
      add :property_id, references(:properties, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:bookings, [:user_id])

    create index(:bookings, [:property_id])
  end
end
