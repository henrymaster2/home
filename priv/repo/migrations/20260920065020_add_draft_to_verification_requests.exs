defmodule Home.Repo.Migrations.AddDraftToVerificationRequests do
  use Ecto.Migration

  def change do
    alter table(:verification_requests) do
      add :draft_data, :map, default: %{}
      add :draft_step, :integer, default: 1
    end
  end
end
