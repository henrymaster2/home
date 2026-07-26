defmodule HomeWeb.ProfileLive do
    use HomeWeb, :live_view
    def mount(_params, _session, socket) do
        {:ok, socket}
    end
    def render(assigns) do
    ~H"""
    <div>
    <p>profile</p>
    </div>
    """
    end
end