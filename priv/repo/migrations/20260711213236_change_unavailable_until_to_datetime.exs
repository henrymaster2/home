defmodule Home.Repo.Migrations.ChangeUnavailableUntilToDatetime do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      # The 'USING' clause tells Postgres safely convert your existing dates into timestamps
      modify :unavailable_until, :naive_datetime,
        from: :date,
        options: "USING unavailable_until::timestamp"
    end
  end
end
