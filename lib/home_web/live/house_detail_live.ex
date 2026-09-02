defmodule HomeWeb.HouseDetailLive do
  use HomeWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> Phoenix.Component.assign(:live_module, __MODULE__), layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen --glass-bg: rgba(10, 10, 10, 0.70) ">House Detail</div>
    """
  end
end
