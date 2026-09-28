defmodule Home.Accounts.LandlordDocument do
  use Ecto.Schema
  import Ecto.Changeset

  @document_types ~w(id_front id_back kra_doc ownership_doc)

  schema "landlord_documents" do
    field :document_type, :string
    field :file_url, :string
    field :original_filename, :string
    field :content_type, :string

    belongs_to :landlord, Home.Accounts.Landlord
    belongs_to :verification_request, Home.Accounts.VerificationRequest
    belongs_to :invite, Home.Accounts.AdminLiteInvite

    timestamps(type: :utc_datetime)
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [
      :document_type,
      :file_url,
      :original_filename,
      :content_type,
      :landlord_id,
      :verification_request_id,
      :invite_id
    ])
    |> validate_required([:document_type, :file_url, :landlord_id])
    |> validate_inclusion(:document_type, @document_types)
    |> foreign_key_constraint(:landlord_id)
    |> foreign_key_constraint(:verification_request_id)
    |> foreign_key_constraint(:invite_id)
    |> unique_constraint([:landlord_id, :document_type])
  end
end
