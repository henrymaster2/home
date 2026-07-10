defmodule HomeWeb.Admin.PropertyLive do
  use HomeWeb, :live_view
  alias Home.Repo
  alias Home.Properties.Property
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:mobile_menu_open, false)
      |> fetch_properties()

    {:ok, socket}
  end

  defp fetch_properties(socket) do
    properties =
      Property
      |> order_by(desc: :id)
      |> Repo.all()
      |> Repo.preload(:property_images)

    assign(socket, :properties, properties)
  end

  @impl true
  def handle_event("toggle_mobile_menu", _, socket) do
    {:noreply, assign(socket, mobile_menu_open: !socket.assigns.mobile_menu_open)}
  end

  @impl true
  def handle_event("delete_property", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    property = Repo.get!(Property, id)
    Repo.delete!(property)

    {:noreply, socket |> put_flash(:info, "Property permanently removed.") |> fetch_properties()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col lg:flex-row min-h-screen bg-zinc-950 text-zinc-100 font-sans antialiased">
      
      <header class="bg-zinc-900 border-b border-zinc-800 px-5 py-4 flex lg:hidden justify-between items-center sticky top-0 z-40">
        <h1 class="text-base font-bold text-white flex items-center gap-2">
          <span class="text-blue-500">🏠</span> Home Admin
        </h1>
        <button phx-click="toggle_mobile_menu" class="px-3 py-1.5 bg-zinc-950 rounded-xl border border-zinc-800 text-zinc-300 hover:text-white transition-all text-xs font-medium">
          <%= if @mobile_menu_open, do: "✕ Close", else: "☰ Menu" %>
        </button>
      </header>

      <aside class={"fixed inset-y-0 left-0 w-64 bg-zinc-900 border-r border-zinc-800 flex flex-col justify-between transform transition-transform duration-300 ease-in-out z-30 lg:translate-x-0 lg:static lg:h-screen #{if @mobile_menu_open, do: "translate-x-0 pt-16 lg:pt-0", else: "-translate-x-full"}"}>
        <div>
          <div class="hidden lg:flex p-6 border-b border-zinc-800/60">
            <h1 class="text-xl font-bold text-white flex items-center gap-2"><span class="text-blue-500">🏠</span> Home Admin</h1>
          </div>
          
          <nav class="p-4 space-y-1.5">
            <.link navigate={~p"/admin"}
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all hover:bg-zinc-800/70 text-zinc-400 hover:text-zinc-100">
              ➕ Add New Unit
            </.link>
            
            <.link navigate={~p"/admin/property"}
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all bg-blue-600 text-white shadow-lg shadow-blue-600/20">
              📋 View Your Houses
            </.link>

            <.link navigate={~p"/admin/bookings"}
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all hover:bg-zinc-800/70 text-zinc-400 hover:text-zinc-100">
              📅 Client Bookings
            </.link>

            <div role="button" title="🚫 Coming Soon"
              class="w-full flex items-center justify-between px-4 py-3 rounded-xl text-sm font-medium transition-all text-zinc-500 bg-zinc-950/20 border border-zinc-900/50 cursor-not-allowed select-none">
              <span class="flex items-center gap-3">💬 Messages</span>
              <span class="bg-zinc-800 text-zinc-500 font-semibold px-1.5 py-0.5 rounded text-[10px]">Soon</span>
            </div>
          </nav>
        </div>
      </aside>

      <main class="flex-1 flex flex-col lg:h-screen lg:overflow-y-auto">
        <header class="bg-zinc-900/40 border-b border-zinc-800 px-8 py-4 hidden lg:flex justify-between items-center">
          <h2 class="text-sm font-medium uppercase tracking-wider text-zinc-400">Manage Properties</h2>
          <span class="text-xs font-semibold text-blue-400 bg-blue-500/10 border border-blue-500/20 px-3 py-1 rounded-full">Live Asset Feed</span>
        </header>

        <div class="p-4 md:p-8 max-w-7xl w-full mx-auto">
          
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for property <- @properties do %>
              <div class="bg-zinc-900/40 border border-zinc-800 rounded-2xl overflow-hidden flex flex-col justify-between shadow-lg backdrop-blur-sm">
                <div>
                  
                  <div class="h-48 bg-zinc-950 overflow-hidden relative group">
                    <%= if img = List.first(property.property_images) do %>
                      <img src={img.image_url} class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                    <% else %>
                      <div class="w-full h-full bg-zinc-900/50 flex items-center justify-center text-xs text-zinc-600 font-medium italic">
                        No Assets Uploaded
                      </div>
                    <% end %>
                    
                    <span class={"absolute top-3 left-3 border text-[10px] px-2.5 py-0.5 rounded-md font-bold tracking-wider uppercase backdrop-blur-md #{status_color_classes(property.status)}"}>
                      <%= property.status %>
                    </span>
                  </div>

                  <div class="p-5 space-y-3">
                    <div>
                      <h4 class="text-base font-bold text-white tracking-tight truncate"><%= property.title %></h4>
                      <p class="text-xs text-zinc-400 flex items-center gap-1 mt-1">
                        <span>📍</span> <%= property.location %> • <span class="text-blue-400 font-medium"><%= property.tier %></span>
                      </p>
                    </div>
                    
                    <div class="flex flex-wrap gap-1.5">
                      <%= if property.wifi do %><span class="text-[10px] bg-zinc-950 px-2 py-0.5 rounded-md border border-zinc-800/80 text-zinc-400 font-medium">📶 WiFi</span><% end %>
                      <%= if property.tv do %><span class="text-[10px] bg-zinc-950 px-2 py-0.5 rounded-md border border-zinc-800/80 text-zinc-400 font-medium">📺 Smart TV</span><% end %>
                      <%= if property.music_system do %><span class="text-[10px] bg-zinc-950 px-2 py-0.5 rounded-md border border-zinc-800/80 text-zinc-400 font-medium">🔊 Sound</span><% end %>
                    </div>

                    <div class="text-xs text-zinc-400 pt-3 border-t border-zinc-800/60 flex justify-between items-center">
                      <span>Night: <strong class="text-zinc-100">KES <%= property.night_price %></strong></span>
                      <span class="w-1.5 h-1.5 rounded-full bg-zinc-700"></span>
                      <span>Day: <strong class="text-zinc-100">KES <%= property.day_price %></strong></span>
                    </div>

                    <%= if property.status != "Available" and not is_nil(property.unavailable_until) do %>
                      <div class="mt-2 text-[11px] font-medium text-amber-400 bg-amber-500/10 border border-amber-500/20 px-3 py-2 rounded-xl flex items-center gap-2">
                        <span>⏳</span> 
                        <span>Till: <strong class="text-zinc-200"><%= format_datetime(property.unavailable_until) %></strong></span>
                      </div>
                    <% end %>

                  </div>
                </div>

                <div class="p-5 pt-0 flex justify-end items-center border-t border-zinc-900/40 mt-2">
                  <button 
                    phx-click="delete_property" 
                    phx-value-id={property.id} 
                    class="text-xs font-medium text-zinc-500 hover:text-red-400 transition-colors duration-150" 
                    data-confirm="Are you sure you want to completely erase this production listing?">
                    Remove Unit
                  </button>
                </div>

              </div>
            <% end %>
          </div>

          <%= if @properties == [] do %>
            <div class="text-center py-24 bg-zinc-900/20 border border-dashed border-zinc-800/80 rounded-3xl max-w-md mx-auto mt-12">
              <span class="text-3xl block mb-3">📂</span>
              <h3 class="text-sm font-semibold text-zinc-300">No properties in production</h3>
              <p class="text-xs text-zinc-500 mt-1 max-w-xs mx-auto">Create a listing from the master dashboard view to see your metrics populate here.</p>
              <.link navigate={~p"/admin"} class="inline-block mt-4 text-xs font-semibold bg-zinc-800 hover:bg-zinc-700 text-blue-400 px-4 py-2 rounded-xl transition-all border border-zinc-700">
                Create First Unit
              </.link>
            </div>
          <% end %>

        </div>
      </main>
    </div>
    """
  end

  # Helpers to change badge colors dynamically based on availability states
  defp status_color_classes("Available"), do: "bg-green-500/10 border-green-500/30 text-green-400"
  defp status_color_classes("Occupied"), do: "bg-red-500/10 border-red-500/30 text-red-400"
  defp status_color_classes("Maintenance"), do: "bg-amber-500/10 border-amber-500/30 text-amber-400"
  defp status_color_classes(_), do: "bg-zinc-800/80 border-zinc-700 text-zinc-300"

  # DateTime, NaiveDateTime, and Date Formatter Helper
  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y at %I:%M %p")
  defp format_datetime(%NaiveDateTime{} = ndt), do: Calendar.strftime(ndt, "%b %d, %Y at %I:%M %p")
  defp format_datetime(%Date{} = d), do: Calendar.strftime(d, "%b %d, %Y")
  defp format_datetime(nil), do: ""
  defp format_datetime(other), do: to_string(other)
end