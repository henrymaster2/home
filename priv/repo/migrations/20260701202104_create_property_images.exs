defmodule Home.Repo.Migrations.CreatePropertyImages do
  use Ecto.Migration

  def change do
    create table(:property_images) do
      add :image_url, :string
      add :property_id, references(:properties, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:property_images, [:user_id])

    create index(:property_images, [:property_id])
  end
end
