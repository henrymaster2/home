defmodule Home.Accounts.VerificationRequest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "verification_requests" do
    field :names, :string
    field :email, :string
    field :phone, :string
    field :status, :string, default: "pending"
    field :user_id, :integer

    timestamps()
  end

  @doc false
  def changeset(verification_request, attrs) do
    verification_request
    |> cast(attrs, [:names, :email, :phone, :status, :user_id])
    |> validate_required([:names, :email, :phone])
    # Add email format validation if needed
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
  end



end
