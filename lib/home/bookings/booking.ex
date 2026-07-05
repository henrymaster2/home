defmodule Home.Bookings.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookings" do
    field :client_name, :string
    field :client_phone, :string
    field :check_in, :date
    field :check_out, :date
    field :total_price, :integer
    field :status, :string, default: "Pending"

    belongs_to :property, Home.Properties.Property

    timestamps()
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [
      :client_name,
      :client_phone,
      :check_in,
      :check_out,
      :total_price,
      :property_id
    ])
    |> validate_required([
      :client_name,
      :client_phone,
      :check_in,
      :check_out,
      :total_price,
      :property_id
    ])
  end
end
