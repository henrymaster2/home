defmodule HomeWeb.Admin.PropertyLive do
  use HomeWeb, :live_view
  alias Home.Repo
  alias Home.Properties.Property
  import Ecto.Query
  import Ecto.Changeset

  @tick_interval :timer.seconds(10)

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :tick, @tick_interval)

    socket =
      socket
      |> assign(:mobile_menu_open, false)
      |> assign(:search_query, "")
      |> fetch_properties()

    {:ok, socket}
  end

  defp fetch_properties(socket) do
    clear_expired_statuses()
    search = socket.assigns[:search_query] || ""

    base_query = Property |> order_by(desc: :id)

    # Dynamically filters your houses by title or location as you type
    query =
      if search != "" do
        from p in base_query,
          where: ilike(p.title, ^"%#{search}%") or ilike(p.location, ^"%#{search}%")
      else
        base_query
      end

    properties =
      query
      |> Repo.all()
      |> Repo.preload(:property_images)

    assign(socket, :properties, properties)
  end

  defp clear_expired_statuses do
    now = NaiveDateTime.local_now()

    Property
    |> where(
      [p],
      p.status != "Available" and not is_nil(p.unavailable_until) and p.unavailable_until <= ^now
    )
    |> Repo.update_all(set: [status: "Available", unavailable_until: nil])
  end

  @impl true
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, @tick_interval)
    {:noreply, fetch_properties(socket)}
  end

  @impl true
  def handle_event("search", %{"search" => search_query}, socket) do
    socket =
      socket
      |> assign(:search_query, search_query)
      |> fetch_properties()

    {:noreply, socket}
  end

  # Handles updating both night and daytime rates inline
  @impl true
  def handle_event(
        "update_prices",
        %{"id" => id_str, "night_price" => night_price, "day_price" => day_price},
        socket
      ) do
    id = String.to_integer(id_str)
    property = Repo.get!(Property, id)

    changeset =
      cast(property, %{"night_price" => night_price, "day_price" => day_price}, [
        :night_price,
        :day_price
      ])

    case Repo.update(changeset) do
      {:ok, _} ->
        {:noreply,
         socket |> put_flash(:info, "Pricing updated successfully.") |> fetch_properties()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update pricing fields.")}
    end
  end

  @impl true
  def handle_event("update_status", %{"id" => id_str, "status" => new_status} = params, socket) do
    id = String.to_integer(id_str)
    property = Repo.get!(Property, id)

    attrs =
      if new_status == "Available" or params["unavailable_until"] == "" do
        %{"status" => new_status, "unavailable_until" => nil}
      else
        %{"status" => new_status, "unavailable_until" => params["unavailable_until"]}
      end

    changeset = cast(property, attrs, [:status, :unavailable_until])

    case Repo.update(changeset) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Property status updated.") |> fetch_properties()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to save status updates.")}
    end
  end

  @impl true
  def handle_event("toggle_mobile_menu", _, socket) do
    {:noreply, assign(socket, mobile_menu_open: !socket.assigns.mobile_menu_open)}
  end

  @impl true
  def handle_event("delete_property", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    property = Property |> Repo.get!(id) |> Repo.preload(:property_images)

    case Repo.transaction(fn ->
           Enum.each(property.property_images, &Repo.delete!/1)
           Repo.delete!(property)
         end) do
      {:ok, _} ->
        {:noreply,
         socket |> put_flash(:info, "Property successfully removed.") |> fetch_properties()}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not remove property item.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col lg:flex-row min-h-screen bg-zinc-950 text-zinc-100 font-sans antialiased selection:bg-blue-600/30 selection:text-blue-200">
      <% # Mobile Top Header %>
      <header class="bg-zinc-900/90 backdrop-blur-md border-b border-zinc-800/80 px-6 py-4 flex lg:hidden justify-between items-center sticky top-0 z-40">
        <h1 class="text-base font-bold text-white flex items-center gap-2 tracking-tight">
          <span class="text-blue-500 text-lg">🏠</span> Host Portal
        </h1>
        <button
          phx-click="toggle_mobile_menu"
          class="px-3.5 py-2 bg-zinc-950 rounded-xl border border-zinc-800 text-zinc-300 hover:text-white hover:border-zinc-700 transition-all text-xs font-semibold tracking-wide"
        >
          {if @mobile_menu_open, do: "✕ Close", else: "☰ Menu"}
        </button>
      </header>

      <% # Sidebar Navigation %>
      <aside class={"fixed inset-y-0 left-0 w-64 bg-zinc-900 border-r border-zinc-800/50 flex flex-col justify-between transform transition-transform duration-300 ease-in-out z-30 lg:translate-x-0 lg:static lg:h-screen #{if @mobile_menu_open, do: "translate-x-0 pt-16 lg:pt-0", else: "-translate-x-full"}"}>
        <div>
          <div class="hidden lg:flex p-6 border-b border-zinc-800/40">
            <h1 class="text-lg font-extrabold text-white flex items-center gap-2.5 tracking-tight">
              <span class="bg-gradient-to-br from-blue-500 to-indigo-600 text-white p-2 rounded-xl shadow-md shadow-blue-500/20 text-xs">
                🏠
              </span>
              <span>Home Hub <span class="text-blue-400">.</span></span>
            </h1>
          </div>

          <nav class="p-4 space-y-1">
            <.link
              navigate={~p"/admin"}
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-bold tracking-wide uppercase transition-all hover:bg-zinc-800/50 text-zinc-400 hover:text-zinc-100"
            >
              ➕ Add New Unit
            </.link>

            <.link
              navigate={~p"/admin/property"}
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-bold tracking-wide uppercase transition-all bg-gradient-to-r from-blue-600 to-indigo-600 text-white shadow-lg shadow-blue-500/10 border border-blue-500/20"
            >
              📋 View Your Houses
            </.link>

            <.link
              navigate={~p"/admin/bookings"}
              class="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-bold tracking-wide uppercase transition-all hover:bg-zinc-800/50 text-zinc-400 hover:text-zinc-100"
            >
              📅 Client Bookings
            </.link>

            <div
              role="button"
              title="Coming Soon"
              class="w-full flex items-center justify-between px-4 py-3 rounded-xl text-xs font-bold tracking-wide uppercase transition-all text-zinc-600 bg-zinc-950/40 border border-zinc-900/60 cursor-not-allowed select-none"
            >
              <span class="flex items-center gap-3">💬 Messages</span>
              <span class="bg-zinc-900 border border-zinc-800 text-zinc-500 font-extrabold px-2 py-0.5 rounded text-[9px] uppercase tracking-normal">
                Soon
              </span>
            </div>
          </nav>
        </div>
      </aside>

      <% # Main UI Body Viewport %>
      <main class="flex-1 flex flex-col lg:h-screen lg:overflow-y-auto">
        <header class="bg-zinc-900/40 border-b border-zinc-800/60 px-8 py-5 hidden lg:flex justify-between items-center backdrop-blur-sm">
          <h2 class="text-xs font-bold uppercase tracking-widest text-zinc-400">
            Property Management Overview
          </h2>
          <span class="text-[10px] font-bold tracking-widest uppercase text-blue-400 bg-blue-500/10 border border-blue-500/20 px-3 py-1.5 rounded-full shadow-inner">
            ● Connected & Live
          </span>
        </header>

        <div class="p-4 md:p-8 max-w-7xl w-full mx-auto space-y-6">
          <% #  Welcoming Interactive Search Component %>
          <div class="bg-zinc-900/40 border border-zinc-800/80 p-4 rounded-2xl backdrop-blur-md shadow-md">
            <form phx-change="search" phx-submit="search" class="relative">
              <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-zinc-500 text-sm">
                🔍
              </div>
              <input
                type="text"
                name="search"
                value={@search_query}
                phx-debounce="200"
                placeholder="Search properties by title, town, or neighborhood..."
                class="w-full bg-zinc-950 border border-zinc-800 focus:border-blue-500/80 rounded-xl pl-10 pr-4 py-3 text-sm text-zinc-100 placeholder-zinc-500 outline-none transition-all focus:ring-4 focus:ring-blue-500/5"
              />
            </form>
          </div>

          <% # Core Layout Grid %>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for property <- @properties do %>
              <div class="bg-zinc-900/30 border border-zinc-800/70 hover:border-zinc-700/80 rounded-2xl overflow-hidden flex flex-col justify-between shadow-xl backdrop-blur-md transition-all duration-300 group hover:shadow-2xl hover:shadow-blue-950/5">
                <div>
                  <% # Photo Canvas Layout %>
                  <div class="h-48 bg-zinc-950 overflow-hidden relative">
                    <%= if Enum.any?(property.property_images) do %>
                      <div class="flex overflow-x-auto snap-x snap-mandatory h-full no-scrollbar scroll-smooth">
                        <%= for img <- property.property_images do %>
                          <div class="w-full h-full flex-shrink-0 snap-center relative">
                            <img
                              src={img.image_url}
                              class="w-full h-full object-cover transition-transform duration-500 group-hover:scale-[1.01]"
                              loading="lazy"
                            />
                          </div>
                        <% end %>
                      </div>
                      <%= if length(property.property_images) > 1 do %>
                        <div class="absolute bottom-3 right-3 bg-zinc-950/80 border border-zinc-800/80 px-2.5 py-1 rounded-lg text-[9px] text-zinc-400 font-bold tracking-wider pointer-events-none select-none uppercase backdrop-blur-sm">
                          ↔ Swipe Gallery ({length(property.property_images)})
                        </div>
                      <% end %>
                    <% else %>
                      <div class="w-full h-full bg-zinc-900/30 flex items-center justify-center text-xs text-zinc-500 font-medium italic tracking-wide">
                        No Assets Uploaded
                      </div>
                    <% end %>

                    <span class={"absolute top-3 left-3 border text-[9px] px-2.5 py-1 rounded-md font-extrabold tracking-widest uppercase backdrop-blur-md shadow-sm #{status_color_classes(property.status)}"}>
                      ● {property.status}
                    </span>
                  </div>

                  <% # Property Info Deck %>
                  <div class="p-5 space-y-4">
                    <div>
                      <h4 class="text-base font-bold text-white tracking-tight group-hover:text-blue-400 transition-colors truncate">
                        {property.title}
                      </h4>
                      <p class="text-xs text-zinc-400 flex items-center gap-1.5 mt-1">
                        <span class="text-zinc-500">📍</span> {property.location} •
                        <span class="text-blue-400 font-semibold uppercase tracking-wider text-[10px]">
                          {property.tier}
                        </span>
                      </p>
                    </div>

                    <% # Feature Pills %>
                    <div class="flex flex-wrap gap-1.5">
                      <%= if property.wifi do %>
                        <span class="text-[9px] bg-zinc-950/80 px-2.5 py-1 rounded-md border border-zinc-800/80 text-zinc-400 font-bold tracking-wide uppercase">
                          📶 WiFi
                        </span>
                      <% end %>
                      <%= if property.tv do %>
                        <span class="text-[9px] bg-zinc-950/80 px-2.5 py-1 rounded-md border border-zinc-800/80 text-zinc-400 font-bold tracking-wide uppercase">
                          📺 Smart TV
                        </span>
                      <% end %>
                      <%= if property.music_system do %>
                        <span class="text-[9px] bg-zinc-950/80 px-2.5 py-1 rounded-md border border-zinc-800/80 text-zinc-400 font-bold tracking-wide uppercase">
                          🔊 Sound
                        </span>
                      <% end %>
                    </div>

                    <% # Dual Price Rate Modification Interface %>
                    <div class="pt-4 border-t border-zinc-800/40">
                      <label class="text-[10px] font-bold tracking-widest text-zinc-400 uppercase block mb-2">
                        Edit Rates (KES)
                      </label>
                      <form phx-submit="update_prices" class="grid grid-cols-2 gap-2">
                        <input type="hidden" name="id" value={property.id} />

                        <div class="bg-zinc-950 p-2 rounded-xl border border-zinc-800 focus-within:border-blue-500/50 transition-all">
                          <span class="block text-[8px] uppercase font-bold text-zinc-500 tracking-wider">
                            🌙 Night Price
                          </span>
                          <input
                            type="number"
                            name="night_price"
                            value={property.night_price}
                            class="w-full bg-transparent text-white font-bold text-xs outline-none pt-0.5 border-none p-0 focus:ring-0 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                          />
                        </div>

                        <div class="bg-zinc-950 p-2 rounded-xl border border-zinc-800 focus-within:border-blue-500/50 transition-all">
                          <span class="block text-[8px] uppercase font-bold text-zinc-500 tracking-wider">
                            ☀️ Day Price
                          </span>
                          <input
                            type="number"
                            name="day_price"
                            value={property.day_price}
                            class="w-full bg-transparent text-white font-bold text-xs outline-none pt-0.5 border-none p-0 focus:ring-0 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                          />
                        </div>

                        <button
                          type="submit"
                          class="col-span-2 text-[9px] font-bold uppercase tracking-wider bg-zinc-800 hover:bg-zinc-700 text-zinc-300 py-1.5 rounded-lg border border-zinc-700/50 transition-all"
                        >
                          💾 Save Pricing Adjustments
                        </button>
                      </form>
                    </div>

                    <% # Booking Release Status Banner %>
                    <%= if property.status != "Available" and not is_nil(property.unavailable_until) do %>
                      <div class="text-[11px] font-medium text-amber-400 bg-amber-500/5 border border-amber-500/10 px-3 py-2 rounded-xl flex items-center gap-2 shadow-inner">
                        <span class="animate-pulse">⏳</span>
                        <span>
                          Locked Until:
                          <strong class="text-zinc-200 font-semibold">
                            {format_datetime(property.unavailable_until)}
                          </strong>
                        </span>
                      </div>
                    <% end %>

                    <% # Status Modifiers %>
                    <div class="pt-4 border-t border-zinc-800/40">
                      <label class="text-[10px] font-bold tracking-widest text-zinc-500 uppercase block mb-2">
                        Availability Settings
                      </label>

                      <form phx-submit="update_status" class="space-y-2.5">
                        <input type="hidden" name="id" value={property.id} />

                        <div class="relative">
                          <select
                            name="status"
                            class="w-full bg-zinc-950 border border-zinc-800 hover:border-zinc-700 text-zinc-200 text-xs font-semibold rounded-xl px-3 py-2.5 outline-none transition-all focus:ring-1 focus:ring-blue-500/50 focus:border-blue-500 cursor-pointer appearance-none"
                          >
                            <option value="Available" selected={property.status == "Available"}>
                              🟢 Available
                            </option>
                            <option value="Occupied" selected={property.status == "Occupied"}>
                              🔴 Occupied / Booked
                            </option>
                            <option value="Maintenance" selected={property.status == "Maintenance"}>
                              🛠️ Maintenance Lock
                            </option>
                          </select>
                          <div class="absolute inset-y-0 right-3 flex items-center pointer-events-none text-zinc-500 text-[9px]">
                            ▼
                          </div>
                        </div>

                        <div class="space-y-1">
                          <span class="text-[9px] font-bold text-zinc-400 tracking-wide uppercase block">
                            Available From (Optional)
                          </span>
                          <input
                            type="datetime-local"
                            name="unavailable_until"
                            value={format_for_input(property.unavailable_until)}
                            class="w-full bg-zinc-950 border border-zinc-800 hover:border-zinc-700 text-zinc-300 text-xs rounded-xl px-3 py-2 outline-none transition-all focus:ring-1 focus:ring-blue-500/50 focus:border-blue-500 tracking-wide text-left"
                          />
                        </div>

                        <button
                          type="submit"
                          class="w-full bg-zinc-900 border border-zinc-800 hover:border-blue-500/40 hover:bg-blue-600 hover:text-white text-zinc-300 text-[10px] font-bold tracking-widest uppercase py-2 px-3 rounded-xl transition-all duration-200 shadow-md"
                        >
                          ⚡ Apply Status Changes
                        </button>
                      </form>
                    </div>
                  </div>
                </div>

                <% # Destructive Deletion Node %>
                <div class="p-4 border-t border-zinc-800/40 bg-zinc-950/30">
                  <button
                    type="button"
                    phx-click="delete_property"
                    phx-value-id={property.id}
                    data-confirm="Are you sure you want to completely remove this listing?"
                    class="w-full bg-red-955/10 hover:bg-red-600 border border-red-900/30 hover:border-red-500 text-red-400 hover:text-white text-xs font-bold py-2.5 px-3 rounded-xl transition-all duration-200 text-center tracking-wide uppercase shadow-sm"
                  >
                    🗑️ Remove Listing
                  </button>
                </div>
              </div>
            <% end %>
          </div>

          <% # Fallback Screen Vector %>
          <%= if @properties == [] do %>
            <div class="text-center py-20 bg-zinc-900/10 border border-dashed border-zinc-800 rounded-3xl max-w-md mx-auto mt-12">
              <span class="text-4xl block mb-4 filter drop-shadow-md">📋</span>
              <h3 class="text-sm font-bold text-zinc-200 uppercase tracking-wide">
                No Properties Match
              </h3>
              <p class="text-xs text-zinc-500 mt-1.5 max-w-xs mx-auto leading-relaxed">
                No real estate assets match your search terms. Try refining your query or add a brand new item.
              </p>
              <.link
                navigate={~p"/admin"}
                class="inline-block mt-5 text-xs font-bold uppercase tracking-wider bg-zinc-900 hover:bg-zinc-800 text-blue-400 px-5 py-2.5 rounded-xl transition-all border border-zinc-800 shadow-lg"
              >
                Create First Unit
              </.link>
            </div>
          <% end %>
        </div>
      </main>
    </div>

    <style>
      .no-scrollbar::-webkit-scrollbar { display: none; }
      .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }

      input[type="datetime-local"]::-webkit-calendar-picker-indicator {
        filter: invert(0.7) sepia(100%) saturate(1000%) hue-rotate(190deg);
        cursor: pointer;
      }
    </style>
    """
  end

  defp status_color_classes("Available"), do: "bg-green-500/5 border-green-500/20 text-green-400"
  defp status_color_classes("Occupied"), do: "bg-red-500/5 border-red-500/20 text-red-400"

  defp status_color_classes("Maintenance"),
    do: "bg-amber-500/5 border-amber-500/20 text-amber-400"

  defp status_color_classes(_), do: "bg-zinc-800/40 border-zinc-700 text-zinc-300"

  defp format_for_input(%NaiveDateTime{} = ndt), do: Calendar.strftime(ndt, "%Y-%m-%dT%H:%M")
  defp format_for_input(_), do: ""

  defp format_datetime(%DateTime{} = dt), do: Calendar.strftime(dt, "%b %d, %Y at %I:%M %p")

  defp format_datetime(%NaiveDateTime{} = ndt),
    do: Calendar.strftime(ndt, "%b %d, %Y at %I:%M %p")

  defp format_datetime(%Date{} = d), do: Calendar.strftime(d, "%b %d, %Y")

  defp format_datetime(binary) when is_binary(binary) do
    case NaiveDateTime.from_iso8601(binary) do
      {:ok, ndt} ->
        format_datetime(ndt)

      _ ->
        case NaiveDateTime.from_iso8601(binary <> ":00") do
          {:ok, ndt} -> format_datetime(ndt)
          _ -> binary
        end
    end
  end

  defp format_datetime(nil), do: ""
  defp format_datetime(other), do: to_string(other)
end
