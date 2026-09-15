defmodule Home.Accounts.AdminLiteInvite do
  use Ecto.Schema
  import Ecto.Changeset

  alias Home.Accounts.User

  schema "admin_lite_invites" do
    field :email, :string
    field :token, :string
    field :invite_type, :string
    field :used, :boolean, default: false
    field :used_at, :utc_datetime
    field :expires_at, :utc_datetime

    belongs_to :created_by, User

    timestamps(type: :utc_datetime)
  end

  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [
      :email,
      :token,
      :used_at,
      :expires_at,
      :invite_type,
      :created_by_id
    ])
    |> validate_required([
      :email,
      :token,
      :expires_at,
      :invite_type,
      :created_by_id
    ])
    |> validate_inclusion(:invite_type, ["admin_lite", "landlord"])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> unique_constraint(:token)
  end
end
