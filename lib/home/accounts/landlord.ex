defmodule Home.Accounts.Landlord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "landlords" do
    field :entity_type, :string, default: "individual"
    field :names, :string
    field :email, :string
    field :phone, :string
    field :whatsapp_phone, :string
    field :residence_location, :string

    # step 2
    field :id_type, :string, default: "National ID"
    field :id_number, :string
    field :kra_pin, :string
    field :id_front_url, :string
    field :id_back_url, :string

    #3 proof of ownership
    # Step 3: Proof of Ownership & Property Details
    field :listing_purpose, :string, default: "renting"
    field :property_name, :string
    field :ownership_type, :string, default: "Freehold title"
    field :lr_number, :string
    field :property_location, :string
    field :total_units, :integer
    field :ownership_doc_url, :string

    belongs_to :user, Home.Accounts.User
    belongs_to :verification_request, Home.Accounts.VerificationRequest

    timestamps()
  end

  @doc """
  Changeset for Step 1: Personal details.
  """
  def personal_details_changeset(landlord \\ %__MODULE__{}, attrs) do
    landlord
    |> cast(attrs, [
      :entity_type,
      :names,
      :email,
      :phone,
      :whatsapp_phone,
      :residence_location,
      :user_id,
      :verification_request_id
    ])
    |> validate_required([:entity_type, :names, :email, :phone])
    |> validate_inclusion(:entity_type, ["individual", "company"])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> unique_constraint(:email)
  end

  #step 2 identity check
  def identity_changeset(landlord, attrs) do
    landlord
    |> cast(attrs, [:id_type, :id_number, :kra_pin, :id_front_url, :id_back_url])
    |> validate_required([:id_type, :id_number, :kra_pin])
    |> validate_format(:kra_pin, ~r/^[A-Z]\d{9}[A-Z]$/i, message: "must be a valid KRA PIN format (e.g., A012345678X)")
  end

  #property changeset
def property_changeset(landlord, attrs) do
    landlord
    |> cast(attrs, [
      :listing_purpose,
      :property_name,
      :ownership_type,
      :lr_number,
      :property_location,
      :total_units,
      :ownership_doc_url
    ])
    |> validate_required([
      :listing_purpose,
      :property_name,
      :ownership_type,
      :lr_number,
      :property_location
    ])
    |> validate_inclusion(:listing_purpose, ["renting", "leasing", "selling", "mixed"])
    |> validate_number(:total_units, greater_than_or_equal_to: 1)
  end

end
