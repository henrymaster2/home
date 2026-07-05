defmodule Home.BookingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Home.Bookings` context.
  """

  @doc """
  Generate a booking.
  """
  def booking_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        check_in: ~D[2026-06-30],
        check_out: ~D[2026-06-30],
        client_name: "some client_name",
        client_phone: "some client_phone",
        status: "some status",
        total_price: 42
      })

    {:ok, booking} = Home.Bookings.create_booking(scope, attrs)
    booking
  end
end
