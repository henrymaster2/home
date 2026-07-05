defmodule Home.PropertiesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Home.Properties` context.
  """

  @doc """
  Generate a property.
  """
  def property_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        day_price: 42,
        location: "some location",
        music_system: true,
        night_price: 42,
        status: "some status",
        tier: "some tier",
        title: "some title",
        tv: true,
        unavailable_until: ~D[2026-06-30],
        wifi: true
      })

    {:ok, property} = Home.Properties.create_property(scope, attrs)
    property
  end

  @doc """
  Generate a property_image.
  """
  def property_image_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        image_url: "some image_url"
      })

    {:ok, property_image} = Home.Properties.create_property_image(scope, attrs)
    property_image
  end
end
