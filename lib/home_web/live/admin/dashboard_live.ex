defmodule HomeWeb.Admin.DashboardLive do

   use HomeWeb, :live_view
  @impl true
   def mount(_params, _session, socket) do
    {:ok, socket}
   end
  @impl true
   def render(assigns) do
    ~H"""
    <div>
      <h1>Admin Dashboard</h1>
      <p>Welcome to the admin dashboard!</p>
    </div>
    """
  end
end
