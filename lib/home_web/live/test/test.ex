defmodule HomeWeb.TestLive do
  use HomeWeb, :live_view
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
  def render(assigns) do
    ~H"""
    <div>
    <p>henry</p>
    </div>
    """
  end
  end