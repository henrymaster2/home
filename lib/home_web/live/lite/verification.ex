defmodule HomeWeb.Verify.Text do

  use HomeWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
    <p> welcome home</p>
    </div>
    """
  end
end
