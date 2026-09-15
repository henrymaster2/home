defmodule Home.Repo.Migrations.AddIdNumberToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :id_number, :string
    end
  end
end
