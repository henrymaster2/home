defmodule Home.Repo.Migrations.CreateLandlordDocuments do
  use Ecto.Migration

  def change do
    alter table(:landlords) do
      add :kra_doc_url, :string
    end

    create table(:landlord_documents) do
      add :document_type, :string, null: false
      add :file_url, :string, null: false
      add :original_filename, :string
      add :content_type, :string
      add :landlord_id, references(:landlords, on_delete: :delete_all), null: false
      add :verification_request_id, references(:verification_requests, on_delete: :nilify_all)
      add :invite_id, references(:admin_lite_invites, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:landlord_documents, [:landlord_id])
    create index(:landlord_documents, [:verification_request_id])
    create index(:landlord_documents, [:invite_id])
    create unique_index(:landlord_documents, [:landlord_id, :document_type])
  end
end
