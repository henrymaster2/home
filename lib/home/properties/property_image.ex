defmodule Home.Properties.PropertyImage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "property_images" do
    field :image_url, :string
    belongs_to :property, Home.Properties.Property

    timestamps()
  end

  def changeset(property_image, attrs) do
    property_image
    |> cast(attrs, [:image_url, :property_id])
    |> validate_required([:image_url])
  end
end
