defmodule HomeWeb.Admin.Notifications do
  use HomeWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      notifications Page
    </div>
    """
  end
end
