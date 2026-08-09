defmodule HomeWeb.Admin.Notifications do
  use HomeWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
  <h1>Notification Page</h1>

  <button
    id="install-pwa"
    hidden
    class="mt-4 rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
  >
    Install Home App
  </button>
</div>
    """
  end
end
