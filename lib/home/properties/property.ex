defmodule Home.Properties.Property do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties" do
    field :title, :string
    field :location, :string
    field :night_price, :integer
    field :day_price, :integer
    field :tier, :string, default: "Normal"
    field :wifi, :boolean, default: false
    field :tv, :boolean, default: false
    field :music_system, :boolean, default: false
    field :status, :string, default: "Available"
    field :unavailable_until, :date

    has_many :property_images, Home.Properties.PropertyImage

    timestamps()
  end

  def changeset(property, attrs) do
    property
    |> cast(attrs, [
      :title,
      :location,
      :night_price,
      :day_price,
      :tier,
      :wifi,
      :tv,
      :music_system,
      :status,
      :unavailable_until
    ])
    |> validate_required([:title, :location, :night_price])
  end
end
