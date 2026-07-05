defmodule HomeWeb.Admin.PropertyLive do
    use HomeWeb, :live_view
    def mount(_params, _session, socket) do
        {:ok, socket}
    end
     def render(assigns) do
    ~H"""
    <div>
      property
    </div>
    """
  end
end