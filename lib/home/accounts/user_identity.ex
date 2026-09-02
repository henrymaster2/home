defmodule Home.Accounts.UserIdentity do
  use Ecto.Schema

  import Ecto.Changeset

  alias Home.Accounts.User

  schema "user_identities" do
    field :provider, :string
    field :provider_user_id, :string

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:provider, :provider_user_id, :user_id])
    |> validate_required([:provider, :provider_user_id, :user_id])
    |> unique_constraint([:provider, :provider_user_id])
  end
end
