defmodule HomeWeb.Admin.BookingsLive do
  use HomeWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div >
      Bookings Page
    </div>
    """
  end
end