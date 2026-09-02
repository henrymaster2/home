defmodule HomeWeb.Text.Test do
  use HomeWeb, :live_view

  @tabs [
    %{id: "airbnb", label: "Airbnb"},
    %{id: "rent", label: "Rent"},
    %{id: "buy", label: "Buy"},
    %{id: "add", label: "Add"}
  ]
  @impl true
  def mount(_params, _session, socket) do
    all = generate_houses()
    tab = "rent"

    {:ok,
     assign(socket,
       all_houses: all,
       houses: filter(all, tab),
       tabs: @tabs,
       active_tab: tab,
       theme: "dark",
       show_modal: false,
       gallery_house_id: nil,
       show_settings: false,
       view: "main",
       active_carousel: %{},
       show_search: false,
       search_query: ""
     )}
  end

  @impl true
  def handle_event("toggle_search", _params, socket) do
    {:noreply, assign(socket, show_search: !socket.assigns.show_search)}
  end

  @impl true
  def handle_event("set_tab", %{"tab" => "add"}, socket) do
    {:noreply, assign(socket, show_modal: true)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab, houses: filter(socket.assigns.all_houses, tab))}
  end

  def handle_event("toggle_theme", _, socket) do
    {:noreply,
     assign(socket, theme: if(socket.assigns.theme == "dark", do: "light", else: "dark"))}
  end

  def handle_event("open_modal", _, socket) do
    {:noreply, assign(socket, show_modal: true)}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, show_modal: false)}
  end

  def handle_event("open_gallery", %{"house" => house_id}, socket) do
    {:noreply, assign(socket, gallery_house_id: String.to_integer(house_id))}
  end

  def handle_event("close_gallery", _params, socket) do
  house_id = socket.assigns.gallery_house_id

  {:noreply,
   socket
   |> assign(:gallery_house_id, nil)
   |> push_patch(to: ~p"/#house-#{house_id}")} # adjust path format to match your router
end

  def handle_event("toggle_settings", _, socket) do
    {:noreply, assign(socket, show_settings: !socket.assigns.show_settings)}
  end

  def handle_event("set_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, view: view)}
  end

  def handle_event("carousel_next", %{"house" => house_id}, socket) do
    house_id = String.to_integer(house_id)
    current = Map.get(socket.assigns.active_carousel, house_id, 0)
    house = Enum.find(socket.assigns.houses, &(&1.id == house_id))
    next = rem(current + 1, length(house.rooms))

    {:noreply,
     assign(socket, active_carousel: Map.put(socket.assigns.active_carousel, house_id, next))}
  end

  def handle_event("carousel_prev", %{"house" => house_id}, socket) do
    house_id = String.to_integer(house_id)
    current = Map.get(socket.assigns.active_carousel, house_id, 0)
    house = Enum.find(socket.assigns.houses, &(&1.id == house_id))
    len = length(house.rooms)
    prev = rem(current - 1 + len, len)

    {:noreply,
     assign(socket, active_carousel: Map.put(socket.assigns.active_carousel, house_id, prev))}
  end

  defp filter(houses, "airbnb"), do: Enum.filter(houses, &(&1.type == "short_stay"))
  defp filter(houses, "rent"), do: Enum.filter(houses, &(&1.type == "rent"))
  defp filter(houses, "buy"), do: Enum.filter(houses, &(&1.type == "buy"))
  defp filter(houses, "add"), do: houses
  defp filter(houses, _), do: houses

  defp generate_houses do
    [
      %{
        id: 1,
        address: "The Glass Pavilion",
        city: "Hudson Valley, NY",
        beds: 4,
        baths: 3,
        sqft: 3200,
        type: "rent",
        rooms: [
          %{
            name: "Exterior",
            image: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&q=80",
            note:
              "An architectural masterpiece blending seamlessly with its forested surroundings."
          },
          %{
            name: "Living Room",
            image: "https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=1200&q=80",
            note: "Floor-to-ceiling glass walls. Morning light floods the space at 7 AM."
          },
          %{
            name: "Kitchen",
            image: "https://images.unsplash.com/photo-1556911220-bff31c812dba?w=1200&q=80",
            note: "Chef's kitchen with marble island and hidden wine cooler."
          },
          %{
            name: "Master Suite",
            image: "https://images.unsplash.com/photo-1616594039964-40891a909d99?w=1200&q=80",
            note: "En-suite with rainfall shower and heated floors."
          }
        ]
      },
      %{
        id: 2,
        address: "Oceanfront Villa",
        city: "Miami Beach, FL",
        beds: 5,
        baths: 4,
        sqft: 4500,
        type: "rent",
        rooms: [
          %{
            name: "Pool Deck",
            image: "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1200&q=80",
            note: "Infinity pool with direct ocean views. Automated lighting at sunset."
          },
          %{
            name: "Kitchen",
            image: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80",
            note: "Open-concept with double oven and smart faucet."
          },
          %{
            name: "Home Office",
            image: "https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200&q=80",
            note: "Soundproofed with gigabit fiber. Video-call ready."
          }
        ]
      },
      %{
        id: 3,
        address: "Cyber Loft",
        city: "Austin, TX",
        beds: 2,
        baths: 2,
        sqft: 1400,
        type: "buy",
        rooms: [
          %{
            name: "Living Area",
            image: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=80",
            note: "Vaulted ceilings with exposed beams and floating fireplace."
          },
          %{
            name: "Kitchen",
            image: "https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=1200&q=80",
            note: "Quartz counters with built-in espresso nook."
          },
          %{
            name: "Garage",
            image: "https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=1200&q=80",
            note: "EV-ready with 240V outlet. Fits two vehicles."
          }
        ]
      },
      %{
        id: 4,
        address: "Sky Penthouse",
        city: "Seattle, WA",
        beds: 3,
        baths: 3,
        sqft: 2800,
        type: "buy",
        rooms: [
          %{
            name: "Rooftop",
            image: "https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=1200&q=80",
            note: "360° city views. Pre-wired for outdoor cinema."
          },
          %{
            name: "Kitchen",
            image: "https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=1200&q=80",
            note: "Triple-basin sink with walk-in fridge."
          },
          %{
            name: "Guest Suite",
            image: "https://images.unsplash.com/photo-1600573472550-8090b5e0745e?w=1200&q=80",
            note: "Private entrance with kitchenette and laundry."
          }
        ]
      },
      %{
        id: 5,
        address: "Cloud Studio",
        city: "Denver, CO",
        beds: 1,
        baths: 1,
        sqft: 650,
        type: "rent",
        rooms: [
          %{
            name: "Studio",
            image: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200&q=80",
            note: "Modular furniture rails. Sleep mode to work mode in seconds."
          }
        ]
      },
      %{
        id: 6,
        address: "Electric Loft",
        city: "Chicago, IL",
        beds: 2,
        baths: 2,
        sqft: 1200,
        type: "rent",
        rooms: [
          %{
            name: "Balcony",
            image: "https://images.unsplash.com/photo-1600573472592-401b489a3cdc?w=1200&q=80",
            note: "South-facing with automated planters and herb garden."
          }
        ]
      },
      %{
        id: 7,
        address: "Binary House",
        city: "Portland, OR",
        beds: 3,
        baths: 2,
        sqft: 1800,
        type: "invest",
        rooms: [
          %{
            name: "Basement",
            image: "https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=1200&q=80",
            note: "Plumbed for second kitchen. Great ADU conversion."
          }
        ]
      },
      %{
        id: 8,
        address: "Warp Suite",
        city: "Los Angeles, CA",
        beds: 1,
        baths: 1,
        sqft: 550,
        type: "short_stay",
        rooms: [
          %{
            name: "Loft",
            image: "https://images.unsplash.com/photo-1600607687644-c7171b42498f?w=1200&q=80",
            note: "Instagram-famous spiral staircase. 4.9★ guest average."
          }
        ]
      }
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div
        id="house-finder"
        phx-hook="HouseFinder"
        class={"house-finder #{if @theme == "dark", do: "dark-theme", else: ""}"}
      >
        <%= if @view == "main" do %>
          {render_main(assigns)}
        <% else %>
          {render_help(assigns)}
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  def render_main(assigns) do
    ~H"""
    <!-- Center Header -->
    <div
      class="fixed top-4 left-1/2 -translate-x-1/2 z-50 flex w-[min(92vw,34rem)] flex-col items-center gap-3"
      id="app-header"
    >
      <div class="flex items-center" id="app-brand">
  <span
    class="editorial-brand text-3xl md:text-4xl font-normal uppercase tracking-wide"
    style="color: var(--color-text)"
  >
    HOME
  </span>
</div>
      <div class="relative flex w-full items-center gap-2">
        <div
          class="flex flex-1 items-center justify-center gap-1 rounded-full p-1 bottom-nav-glass shadow-xl"
          id="top-nav"
        >
          <%= for tab <- @tabs do %>
            <button
              phx-click="set_tab"
              phx-value-tab={tab.id}
              class={[
                "min-w-0 flex-1 px-3 py-2 rounded-full text-[11px] md:text-xs font-bold tracking-wide transition-all duration-300 backdrop-blur-md",
                if(@active_tab == tab.id, do: "top-tab-active", else: "top-tab-inactive")
              ]}
            >
              {tab.label}
            </button>
          <% end %>
        </div>

    <!-- SEARCH BUTTON -->
        <button
          phx-click="toggle_search"
          class="shrink-0 w-10 h-10 rounded-full bottom-nav-glass flex items-center justify-center shadow-xl transition-all duration-200 active:scale-90"
          style="color: var(--color-text-dim)"
          aria-label="Search"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="1.5"
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
            />
          </svg>
        </button>

    <!-- SEARCH OVERLAY -->
        <%= if @show_search do %>
          <div class="absolute right-0 top-12 z-[100] w-[min(80vw,20rem)] rounded-2xl p-2 bottom-nav-glass shadow-2xl">
            <div class="flex items-center gap-2">
              <svg
                class="w-5 h-5 shrink-0"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                style="color: var(--color-text-dim)"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="1.5"
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>

              <input
                type="text"
                placeholder="Search..."
                value={@search_query}
                class="w-full bg-transparent border-none outline-none text-sm"
                style="color: var(--color-text)"
              />

              <button
                phx-click="toggle_search"
                class="shrink-0 text-xs"
                style="color: var(--color-text-dim)"
              >
                ✕
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>

    <!-- Bottom Navigation -->
    <nav
      id="bottom-nav"
      class="fixed bottom-4 left-1/2 z-80 flex w-[min(92vw,26rem)] -translate-x-1/2 items-center justify-around rounded-3xl px-4 py-3 shadow-2xl bottom-nav-glass"
      aria-label="Primary navigation"
    >
     <button id="bottom-home-button" type="button" class="bottom-nav-item flex min-w-12 flex-col items-center gap-0.5" style="color: var(--color-text)" aria-label="Home">

  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-5">
  <path d="M14.916 2.404a.75.75 0 0 1-.32 1.011l-.596.31V17a1 1 0 0 1-1 1h-2.26a.75.75 0 0 1-.75-.75v-3.5a.75.75 0 0 0-.75-.75H6.75a.75.75 0 0 0-.75.75v3.5a.75.75 0 0 1-.75.75h-3.5a.75.75 0 0 1 0-1.5H2V9.957a.75.75 0 0 1-.596-1.372L2 8.275V5.75a.75.75 0 0 1 1.5 0v1.745l10.404-5.41a.75.75 0 0 1 1.012.319ZM15.861 8.57a.75.75 0 0 1 .736-.025l1.999 1.04A.75.75 0 0 1 18 10.957V16.5h.25a.75.75 0 0 1 0 1.5h-2a.75.75 0 0 1-.75-.75V9.21a.75.75 0 0 1 .361-.64Z" />
  </svg>

  <span class="text-[8px] font-bold tracking-wider">
    HOME
  </span>
     </button>

      <button
        id="bottom-saved-button"
        type="button"
        class="bottom-nav-item flex min-w-12 flex-col items-center gap-0.5"
        style="color: var(--color-text)"
        aria-label="Saved"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
             <path stroke-linecap="round" stroke-linejoin="round" d="M17.593 3.322c1.1.128 1.907 1.077 1.907 2.185V21L12 17.25 4.5 21V5.507c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0 1 11.186 0Z" />
         </svg>

        <span class="text-[8px] font-bold tracking-wider">SAVED</span>
      </button>

      <button
        id="bottom-profile-button"
        type="button"
        phx-click="toggle_settings"
        class="bottom-nav-item flex min-w-12 flex-col items-center gap-0.5"
        style="color: var(--color-text-dim)"
        aria-label="Profile"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
          <path stroke-linecap="round" stroke-linejoin="round" d="M17.982 18.725A7.488 7.488 0 0 0 12 15.75a7.488 7.488 0 0 0-5.982 2.975m11.963 0a9 9 0 1 0-11.963 0m11.963 0A8.966 8.966 0 0 1 12 21a8.966 8.966 0 0 1-5.982-2.275M15 9.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
              </svg>

        <span class="text-[8px] font-bold tracking-wider">PROFILE</span>
      </button>

      <button
        id="bottom-help-button"
        type="button"
        phx-click="set_view"
        phx-value-view="help"
        class="bottom-nav-item flex min-w-12 flex-col items-center gap-0.5"
        style="color: var(--color-text-dim)"
        aria-label="Help"
      >
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="size-6">
        <path fill-rule="evenodd" d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12Zm8.706-1.442c1.146-.573 2.437.463 2.126 1.706l-.709 2.836.042-.02a.75.75 0 0 1 .67 1.34l-.04.022c-1.147.573-2.438-.463-2.127-1.706l.71-2.836-.042.02a.75.75 0 1 1-.671-1.34l.041-.022ZM12 9a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5Z" clip-rule="evenodd" />
           </svg>

        <span class="text-[8px] font-bold tracking-wider">HELP</span>
      </button>
    </nav>

    <!-- Settings Sheet -->
    <%= if @show_settings do %>
     <div
  class="fixed inset-0 z-55 flex items-end justify-center p-0"
  style="background: rgba(0,0,0,0.3); backdrop-filter: blur(4px);"
  phx-click="toggle_settings"
>
  <div
    class="settings-sheet w-full max-w-md mx-auto max-h-[85vh] overflow-y-auto overscroll-contain rounded-t-3xl p-6 pb-24"
    phx-click=""
    style="background: var(--glass-bg-strong); border-top: 1px solid var(--glass-border); box-shadow: 0 -10px 40px rgba(0,0,0,0.3);"
  >
          <div
            class="w-10 h-1 rounded-full mx-auto mb-6 opacity-30"
            style="background: var(--color-text)"
          >
          </div>
          <h3 class="text-lg font-bold font-mono mb-5 text-center" style="color: var(--color-text)">
            Settings
          </h3>
          <div class="space-y-3">
            <div
              class="flex items-center justify-between p-4 rounded-2xl"
              style="background: color-mix(in srgb, var(--color-bg) 80%, transparent);"
            >
              <div class="flex items-center gap-3">
                <div
                  class="w-9 h-9 rounded-xl flex items-center justify-center"
                  style="background: color-mix(in srgb, var(--accent-1) 12%, transparent); color: var(--accent-1)"
                >
                  <%= if @theme == "dark" do %>
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
                      />
                    </svg>
                  <% else %>
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
                      />
                    </svg>
                  <% end %>
                </div>
                <span class="text-sm font-semibold" style="color: var(--color-text)">Dark Mode</span>
              </div>
              <button
                phx-click="toggle_theme"
                class="relative w-12 h-7 rounded-full transition-colors duration-300"
                style={"background: #{if(@theme == "dark", do: "var(--accent-1)", else: "color-mix(in srgb, var(--color-text-dim) 30%, transparent)")}"}
              >
                <div class={"absolute top-0.5 w-6 h-6 rounded-full bg-white shadow-md transition-transform duration-300 #{if @theme == "dark", do: "translate-x-5", else: "translate-x-0.5"}"}>
                </div>
              </button>
            </div>
            <div
              class="flex items-center justify-between p-4 rounded-2xl"
              style="background: color-mix(in srgb, var(--color-bg) 80%, transparent);"
            >
              <div class="flex items-center gap-3">
                <div
                  class="w-9 h-9 rounded-xl flex items-center justify-center"
                  style="background: color-mix(in srgb, var(--accent-2) 12%, transparent); color: var(--accent-2)"
                >
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
                    />
                  </svg>
                </div>
                <span class="text-sm font-semibold" style="color: var(--color-text)">
                  Notifications
                </span>
              </div>
              <span class="text-xs font-mono opacity-40" style="color: var(--color-text-dim)">
                Soon
              </span>
            </div>
            <div class="flex items-center justify-between p-4 rounded-2xl"
              style="background: color-mix(in srgb, var(--color-bg) 80%, transparent);"><span class="text-sm font-semibold" style="color: var(--color-text)">henry </span></div>
          </div>
        </div>
      </div>
    <% end %>

    <%= if @gallery_house_id do %>
      <% gallery_house = Enum.find(@houses, &(&1.id == @gallery_house_id)) %>
      <%= if gallery_house do %>
        <div
          id="image-gallery-overlay"
          class="fixed inset-0 z-70 flex items-center justify-center p-4 md:p-8"
          style="background: rgba(0,0,0,0.42); backdrop-filter: blur(10px);"
          phx-click="close_gallery"
        >
          <div
            class="relative h-full w-full max-w-6xl overflow-hidden rounded-3xl border"
            style="border-color: color-mix(in srgb, var(--accent-1) 50%, transparent); background: color-mix(in srgb, var(--color-bg) 70%, transparent);"
            phx-click=""
          >
            <div class="absolute left-4 right-4 top-4 z-10 flex items-center justify-between gap-3">
              <div class="glass-panel rounded-2xl px-4 py-3">
                <h3 class="font-mono text-sm font-bold" style="color: var(--color-text)">
                  {gallery_house.address}
                </h3>
                <p class="text-xs" style="color: var(--color-text-dim)">
                  {gallery_house.city}
                </p>
              </div>
              <button
                id="close-gallery-button"
                phx-click="close_gallery"
                class="glass-panel flex h-11 w-11 items-center justify-center rounded-full transition hover:scale-105 active:scale-95"
                style="color: var(--color-text)"
                aria-label="Close gallery"
              >
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="size-5">
             <path d="M3.28 2.22a.75.75 0 0 0-1.06 1.06L5.44 6.5H2.75a.75.75 0 0 0 0 1.5h4.5A.75.75 0 0 0 8 7.25v-4.5a.75.75 0 0 0-1.5 0v2.69L3.28 2.22ZM13.5 2.75a.75.75 0 0 0-1.5 0v4.5c0 .414.336.75.75.75h4.5a.75.75 0 0 0 0-1.5h-2.69l3.22-3.22a.75.75 0 0 0-1.06-1.06L13.5 5.44V2.75ZM3.28 17.78l3.22-3.22v2.69a.75.75 0 0 0 1.5 0v-4.5a.75.75 0 0 0-.75-.75h-4.5a.75.75 0 0 0 0 1.5h2.69l-3.22 3.22a.75.75 0 1 0 1.06 1.06ZM13.5 14.56l3.22 3.22a.75.75 0 1 0 1.06-1.06l-3.22-3.22h2.69a.75.75 0 0 0 0-1.5h-4.5a.75.75 0 0 0-.75.75v4.5a.75.75 0 0 0 1.5 0v-2.69Z" />
                      </svg>

              </button>
            </div>

            <div
              id="gallery-images"
              class="h-full snap-y snap-mandatory overflow-y-auto scroll-smooth"
            >
              <%= for room <- gallery_house.rooms do %>
                <figure class="relative flex min-h-full snap-start items-center justify-center p-3 md:p-8">
                  <img
                    src={room.image}
                    alt={room.name}
                    class="max-h-[86vh] w-full rounded-2xl object-contain shadow-2xl"
                    loading="lazy"
                  />
                  <figcaption class="glass-panel absolute bottom-24 left-1/2 max-h-36 w-[min(88vw,42rem)] -translate-x-1/2 overflow-y-auto overscroll-contain rounded-2xl p-4 touch-pan-y">
                               <p
                            class="mb-1 text-xs font-bold uppercase tracking-widest"
                          style="color: var(--accent-1)"
                          >
                         {room.name}
                          </p>
                        <p class="text-sm leading-relaxed" style="color: var(--color-text)">
                       {room.note}
                       </p>
                         </figcaption>
                </figure>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    <% end %>

    <!-- Signup Modal -->
    <%= if @show_modal do %>
      <div
        class="fixed inset-0 z-60 flex items-center justify-center p-4"
        style="background: rgba(0,0,0,0.5); backdrop-filter: blur(12px);"
        phx-click="close_modal"
      >
        <div
          class="glass-panel rounded-3xl p-8 max-w-sm w-full relative float-anim border shadow-2xl"
          phx-click=""
        >
          <button
            phx-click="close_modal"
            class="absolute top-4 right-4 w-8 h-8 rounded-full flex items-center justify-center opacity-40 hover:opacity-100 transition-opacity"
            style="color: var(--color-text)"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
          <div class="text-center mb-6">
            <div
              class="w-12 h-12 rounded-full mx-auto mb-3 flex items-center justify-center border"
              style="border-color: color-mix(in srgb, var(--accent-1) 30%, transparent); background: color-mix(in srgb, var(--accent-1) 8%, transparent);"
            >
              <svg
                class="w-6 h-6"
                style="color: var(--accent-1)"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 10V3L4 14h7v7l9-11h-7z"
                />
              </svg>
            </div>
            <h2 class="text-2xl font-bold font-mono" style="color: var(--color-text)">Join HOME</h2>
            <p class="text-sm mt-1" style="color: var(--color-text-dim)">
              Unlock prices & talk to owners.
            </p>
          </div>
          <div class="space-y-3">
            <button
              class="w-full py-3 px-4 rounded-xl font-medium text-sm flex items-center justify-center gap-3 transition-all hover:scale-[1.02] active:scale-95 border"
              style="background: white; color: #333; border-color: #e5e5e5;"
            >
              <svg class="w-5 h-5" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                /><path
                  fill="#34A853"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                /><path
                  fill="#FBBC05"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                /><path
                  fill="#EA4335"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              Continue with Google
            </button>
            <button
              class="w-full py-3 px-4 rounded-xl font-medium text-sm flex items-center justify-center gap-3 transition-all hover:scale-[1.02] active:scale-95 text-white"
              style="background: #000;"
            >
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.22 7.13-.57 1.5-1.31 2.99-2.27 4.08zm-5.85-15.1c.07-1.04.88-2.15 1.95-2.58 1.04.15 2.01.9 2.25 2.48-1.15.13-2.24-.82-2.41-1.9h.21z" />
              </svg>
              Continue with Apple
            </button>
          </div>
          <p class="text-center text-xs mt-5 opacity-30" style="color: var(--color-text-dim)">
            Join 2,400 hunters. No email forms.
          </p>
        </div>
      </div>
    <% end %>

    <!-- Main Scroll for viewing house detals -->
    <div
      id="cinematic-scroll"
      class="h-screen w-full overflow-y-auto snap-y snap-mandatory scroll-smooth relative z-10"
    >

    <!-- HERO -->
      <div
        class="house-section hero-section relative w-full overflow-hidden snap-start shrink-0 flex items-center justify-center"
        data-index="0"
      >
        <div class="hero-grid-floor absolute bottom-0 left-0 right-0 h-1/2 pointer-events-none"></div>
        <div class="absolute inset-0 pointer-events-none overflow-hidden">
          <div class="particle" style="left:10%;top:20%;animation-delay:0s"></div>
          <div class="particle" style="left:30%;top:60%;animation-delay:1.2s"></div>
          <div class="particle" style="left:70%;top:30%;animation-delay:2.5s"></div>
          <div class="particle" style="left:85%;top:70%;animation-delay:0.8s"></div>
          <div class="particle" style="left:50%;top:15%;animation-delay:3.1s"></div>
        </div>

        <div class="relative z-10 w-full max-w-5xl mx-auto px-6 flex flex-col items-center">
          <div class="hologram-frame w-full max-w-3xl aspect-video relative mb-8" id="hero-hologram">
            <div class="hologram-screen absolute inset-0 overflow-hidden rounded-2xl">
              <img
                src="https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200&q=80"
                class="holo-slide active"
                alt=""
              />
              <img
                src="https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1200&q=80"
                class="holo-slide"
                alt=""
              />
              <img
                src="https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80"
                class="holo-slide"
                alt=""
              />
              <img
                src="https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=80"
                class="holo-slide"
                alt=""
              />
              <div class="absolute inset-0 bg-linear-to-t from-black/70 via-transparent to-black/30">
              </div>
              <div class="hologram-scanline absolute inset-0 pointer-events-none"></div>
            </div>

            <div class="absolute inset-0 flex flex-col items-center justify-center text-center p-6 z-10">
              <div
                class="location-pill glass-panel px-3 py-1 rounded-full text-[10px] md:text-xs font-mono font-bold tracking-widest mb-4 flex items-center gap-2 border"
                style="color: var(--accent-1); border-color: color-mix(in srgb, var(--accent-1) 30%, transparent);"
              >
                <span
                  class="w-2 h-2 rounded-full animate-pulse"
                  style="background: var(--accent-1); box-shadow: 0 0 8px var(--accent-1)"
                >
                </span>
                DETECTED: NAIROBI, KENYA
              </div>
              <h1
                class="text-3xl md:text-6xl font-bold font-mono mb-3 leading-tight"
                style="color: var(--color-text); text-shadow: 0 0 40px color-mix(in srgb, var(--accent-1) 20%, transparent);"
              >
                In Nairobi,<br />we got you covered.
              </h1>
              <p
                class="text-sm md:text-lg font-mono tracking-wide"
                style="color: var(--color-text-dim)"
              >
                Rentals • Airbnb • Investment Properties
              </p>
            </div>

            <div
              class="absolute -inset-1 rounded-2xl pointer-events-none"
              style="background: linear-gradient(45deg, var(--accent-1), transparent, var(--accent-2)); opacity: 0.3; filter: blur(12px);"
            >
            </div>
            <div
              class="absolute inset-0 rounded-2xl border pointer-events-none"
              style="border-color: color-mix(in srgb, var(--accent-1) 20%, transparent);"
            >
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 w-full max-w-3xl mb-8">
            <div class="glass-panel rounded-xl p-4 flex items-start gap-3 hover:scale-[1.02] transition-transform cursor-default">
              <div
                class="w-10 h-10 rounded-lg flex items-center justify-center shrink-0"
                style="background: color-mix(in srgb, var(--accent-1) 10%, transparent); color: var(--accent-1)"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                  /><path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
              </div>
              <div>
                <h3 class="text-sm font-bold font-mono mb-1" style="color: var(--color-text)">
                  Get easiy experience in house hunting
                </h3>
                <p class="text-xs leading-relaxed" style="color: var(--color-text-dim)">
                  Exact address released only after both parties agree.
                </p>
              </div>
            </div>
            <div class="glass-panel rounded-xl p-4 flex items-start gap-3 hover:scale-[1.02] transition-transform cursor-default">
              <div
                class="w-10 h-10 rounded-lg flex items-center justify-center shrink-0"
                style="background: color-mix(in srgb, var(--accent-2) 10%, transparent); color: var(--accent-2)"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
              <div>
                <h3 class="text-sm font-bold font-mono mb-1" style="color: var(--color-text)">
                  Owner Verified
                </h3>
                <p class="text-xs leading-relaxed" style="color: var(--color-text-dim)">
                  Poster must accept your location request before reveal.
                </p>
              </div>
            </div>
            <div class="glass-panel rounded-xl p-4 flex items-start gap-3 hover:scale-[1.02] transition-transform cursor-default">
              <div
                class="w-10 h-10 rounded-lg flex items-center justify-center shrink-0"
                style="background: color-mix(in srgb, var(--accent-1) 10%, transparent); color: var(--accent-1)"
              >
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
              </div>
              <div>
                <h3 class="text-sm font-bold font-mono mb-1" style="color: var(--color-text)">
                  Join the Community
                </h3>
                <p class="text-xs leading-relaxed" style="color: var(--color-text-dim)">
                  2,400+ members already hunting in your area.
                </p>
              </div>
            </div>
          </div>

          <div class="flex flex-col items-center gap-2 animate-bounce-slow">
            <span
              class="text-[10px] font-mono tracking-[0.2em] uppercase"
              style="color: var(--color-text-dim)"
            >
              Scroll to explore
            </span>
            <svg
              class="w-5 h-5"
              style="color: var(--accent-1)"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 14l-7 7m0 0l-7-7m7 7V3"
              />
            </svg>
          </div>
        </div>
      </div>

    <!-- HOUSE CARDS -->
      <%= for {house, index} <- Enum.with_index(@houses) do %>
        <% room_idx = Map.get(@active_carousel, house.id, 0) %>
        <% current_room = Enum.at(house.rooms, room_idx) %>
        <div
          class={[
            "house-section relative w-full overflow-hidden snap-start shrink-0",
            if(index >= 4, do: "opacity-25 pointer-events-none", else: "")
          ]}
          data-index={index + 1}
        >

    <!-- Blurred background from first room image -->
          <div class="absolute inset-0 z-0 overflow-hidden">
            <img
              src={List.first(house.rooms).image}
              alt=""
              class="w-full h-full object-cover bg-blur-rich"
              loading="lazy"
            />
            <div class="absolute inset-0 bg-linear-to-t from-black/80 via-black/30 to-black/50"></div>
            <div class="absolute inset-0 color-veil"></div>
          </div>

          <%= if index < 4 do %>
            <!-- Desktop: Split View -->
            <div class="absolute inset-x-0 top-28 bottom-24 z-10 hidden  items-stretch justify-center gap-8 px-10 md:flex">
              <!-- Left: Carousel Card -->
              <div
                class="relative h-full w-[52%] max-w-3xl rounded-3xl overflow-hidden shadow-2xl border"
                style="border-color: color-mix(in srgb, var(--accent-1) 15%, transparent);"
              >
                <%= for {room, ridx} <- Enum.with_index(house.rooms) do %>
                  <img
                    src={room.image}
                    alt=""
                    class={"absolute inset-0 w-full h-full object-cover transition-opacity duration-500 #{if ridx == room_idx, do: "opacity-100", else: "opacity-0"}"}
                  />
                <% end %>
                <div class="absolute inset-0 bg-linear-to-t from-black/60 to-transparent"></div>
                <button
                  id={"open-gallery-#{house.id}"}
                  phx-click="open_gallery"
                  phx-value-house={house.id}
                  class="absolute right-4 top-4 z-10 flex h-11 w-11 items-center justify-center rounded-full border transition hover:scale-105 active:scale-95"
                  style="background: rgba(0,0,0,0.24); border-color: rgba(255,255,255,0.25); color: white; backdrop-filter: blur(14px);"
                  aria-label="Open image gallery"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 3.75v4.5m0-4.5h4.5m-4.5 0L9 9M3.75 20.25v-4.5m0 4.5h4.5m-4.5 0L9 15M20.25 3.75h-4.5m4.5 0v4.5m0-4.5L15 9m5.25 11.25h-4.5m4.5 0v-4.5m0 4.5L15 15" />
                  </svg>

                </button>

    <!-- Carousel Controls -->
                <button
                  phx-click="carousel_prev"
                  phx-value-house={house.id}
                  class="absolute left-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full glass-panel flex items-center justify-center hover:scale-110 transition-transform"
                >
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M15 19l-7-7 7-7"
                    />
                  </svg>
                </button>
                <button
                  phx-click="carousel_next"
                  phx-value-house={house.id}
                  class="absolute right-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full glass-panel flex items-center justify-center hover:scale-110 transition-transform"
                >
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </button>

    <!-- Dots -->
                <div class="absolute bottom-4 left-1/2 -translate-x-1/2 flex gap-1.5">
                  <%= for {_room, ridx} <- Enum.with_index(house.rooms) do %>
                    <div
                      class={"w-1.5 h-1.5 rounded-full transition-all #{if ridx == room_idx, do: "w-4", else: ""}"}
                      style={"background: #{if ridx == room_idx, do: "var(--accent-1)", else: "rgba(255,255,255,0.3)"}"}
                    >
                    </div>
                  <% end %>
                </div>

    <!-- Room Badge -->
                <div
                  class="absolute top-4 left-4 px-3 py-1 rounded-full text-[10px] font-bold font-mono uppercase tracking-wider border glass-panel"
                  style="color: var(--accent-1); border-color: color-mix(in srgb, var(--accent-1) 30%, transparent);"
                >
                  {current_room.name}
                </div>
                <div class="absolute bottom-5 left-5 right-5 rounded-2xl border p-4 shadow-2xl note-overlay-card">
                  <p
                    class="mb-1 text-[10px] font-bold uppercase tracking-widest"
                    style="color: var(--accent-1)"
                  >
                    {current_room.name}
                  </p>
                  <p class="text-sm leading-relaxed" style="color: white">
                    {current_room.note}
                  </p>
                </div>
              </div>

    <!-- Right: Details Panel -->
              <div class="flex w-[34%] max-w-md flex-col justify-center glass-panel rounded-3xl p-6 pointer-events-auto">
                <div class="mb-5">
                  <div>
                    <h2
                      class="text-3xl font-bold font-mono leading-tight"
                      style="color: var(--color-text)"
                    >
                      {house.address}
                    </h2>
                    <p class="text-sm mt-1 font-mono" style="color: var(--color-text-dim)">
                      {house.city}
                    </p>
                  </div>
                </div>

                <div
                  class="flex items-center gap-5 mb-5 text-xs font-mono"
                  style="color: var(--color-text-dim)"
                >
                  <span class="flex items-center gap-1.5">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2h-5l-5 5v5H5v-5a2 2 0 012-2h10a2 2 0 012 2v5"
                      />
                    </svg>
                    {house.beds} BD
                  </span>
                  <span class="flex items-center gap-1.5">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                      />
                    </svg>
                    {house.baths} BA
                  </span>
                  <span class="flex items-center gap-1.5">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"
                      />
                    </svg>
                    {house.sqft} SF
                  </span>
                </div>

                <div class="text-center mb-4 cursor-pointer group" phx-click="open_modal">
                  <div
                    class="inline-flex items-center gap-2 px-4 py-2 rounded-xl border transition-colors"
                    style="border-color: color-mix(in srgb, var(--accent-1) 20%, transparent); background: color-mix(in srgb, var(--accent-1) 4%, transparent);"
                  >
                    <span
                      class="text-2xl font-bold font-mono tracking-[0.25em] shimmer-text"
                      style="color: var(--accent-1)"
                    >
                      ●●●●
                    </span>
                    <svg
                      class="w-4 h-4 opacity-40"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                      />
                    </svg>
                  </div>
                  <p
                    class="text-[10px] uppercase tracking-widest mt-2 opacity-30"
                    style="color: var(--color-text-dim)"
                  >
                    Tap to unlock price
                  </p>
                </div>

                <div class="flex gap-3">
                  <button
                    phx-click="open_modal"
                    class="flex-1 py-3 rounded-xl font-semibold text-sm border transition-all hover:scale-[1.02] active:scale-95 flex items-center justify-center gap-2"
                    style="border-color: color-mix(in srgb, var(--accent-1) 40%, transparent); color: var(--accent-1);"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                      />
                    </svg>
                    Message Owner
                  </button>
                  <button
                    phx-click="open_modal"
                    class="flex-1 py-3 rounded-xl font-semibold text-sm text-white transition-all hover:scale-[1.02] active:scale-95 flex items-center justify-center gap-2 shadow-lg"
                    style="background: linear-gradient(135deg, var(--accent-1), var(--accent-2));"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
                      />
                    </svg>
                    Save to Board
                  </button>
                </div>
              </div>
            </div>

    <!-- Mobile: Stacked Card -->
            <div class="absolute inset-x-0 top-28 bottom-24 z-10 flex items-stretch p-4 pointer-events-none md:hidden">
              <div class="glass-panel mx-auto flex h-full w-full max-w-md flex-col overflow-hidden rounded-3xl pointer-events-auto">
                <!-- Carousel -->
                <div class="relative min-h-72 flex-[1_1_auto] overflow-hidden">
                  <%= for {room, ridx} <- Enum.with_index(house.rooms) do %>
                    <img
                      src={room.image}
                      alt=""
                      class={"absolute inset-0 w-full h-full object-cover transition-opacity duration-500 #{if ridx == room_idx, do: "opacity-100", else: "opacity-0"}"}
                    />
                  <% end %>
                  <div class="absolute inset-0 bg-linear-to-t from-black/60 to-transparent"></div>
                  <button
                    id={"open-gallery-mobile-#{house.id}"}
                    phx-click="open_gallery"
                    phx-value-house={house.id}
                    class="absolute right-3 top-3 z-10 flex h-9 w-9 items-center justify-center rounded-full border transition active:scale-95"
                    style="background: rgba(0,0,0,0.24); border-color: rgba(255,255,255,0.25); color: white; backdrop-filter: blur(14px);"
                    aria-label="Open image gallery"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6">
                         <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 3.75v4.5m0-4.5h4.5m-4.5 0L9 9M3.75 20.25v-4.5m0 4.5h4.5m-4.5 0L9 15M20.25 3.75h-4.5m4.5 0v4.5m0-4.5L15 9m5.25 11.25h-4.5m4.5 0v-4.5m0 4.5L15 15" />
                   </svg>

                  </button>

                  <button
                    phx-click="carousel_prev"
                    phx-value-house={house.id}
                    class="absolute left-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full glass-panel flex items-center justify-center"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M15 19l-7-7 7-7"
                      />
                    </svg>
                  </button>
                  <button
                    phx-click="carousel_next"
                    phx-value-house={house.id}
                    class="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full glass-panel flex items-center justify-center"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </button>

                  <div class="absolute bottom-3 left-1/2 -translate-x-1/2 flex gap-1.5">
                    <%= for {_room, ridx} <- Enum.with_index(house.rooms) do %>
                      <div
                        class={"w-1.5 h-1.5 rounded-full transition-all #{if ridx == room_idx, do: "w-4", else: ""}"}
                        style={"background: #{if ridx == room_idx, do: "var(--accent-1)", else: "rgba(255,255,255,0.3)"}"}
                      >
                      </div>
                    <% end %>
                  </div>

                  <div
                    class="absolute top-3 left-3 px-2.5 py-0.5 rounded-full text-[9px] font-bold font-mono uppercase tracking-wider border glass-panel"
                    style="color: var(--accent-1); border-color: color-mix(in srgb, var(--accent-1) 30%, transparent);"
                  >
                    {current_room.name}
                  </div>
                  <div class="absolute bottom-8 left-3 right-3 rounded-2xl border p-3 shadow-2xl note-overlay-card">
                    <p
                      class="mb-1 text-[9px] font-bold uppercase tracking-widest"
                      style="color: var(--accent-1)"
                    >
                      {current_room.name}
                    </p>
                    <p class="text-xs leading-relaxed" style="color: white">
                      {current_room.note}
                    </p>
                  </div>
                </div>

i    <!-- Info -->
                <div class="shrink-0 p-4">
                  <div class="mb-3">
                    <div>
                      <h2
                        class="text-lg font-bold font-mono leading-tight"
                        style="color: var(--color-text)"
                      >
                        {house.address}
                      </h2>
                      <p class="text-xs mt-0.5 font-mono" style="color: var(--color-text-dim)">
                        {house.city}
                      </p>
                    </div>
                  </div>

                  <div
                    class="flex items-center gap-4 mb-3 text-[10px] font-mono"
                    style="color: var(--color-text-dim)"
                  >
                    <span class="flex items-center gap-1">
                      <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2h-5l-5 5v5H5v-5a2 2 0 012-2h10a2 2 0 012 2v5"
                        /></svg>{house.beds} BD
                    </span>
                    <span class="flex items-center gap-1">
                      <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                        /></svg>{house.baths} BA
                    </span>
                    <span class="flex items-center gap-1">
                      <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"
                        /></svg>{house.sqft} SF
                    </span>
                  </div>

                  <div class="text-center mb-3 cursor-pointer" phx-click="open_modal">
                    <div
                      class="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl border"
                      style="border-color: color-mix(in srgb, var(--accent-1) 20%, transparent); background: color-mix(in srgb, var(--accent-1) 4%, transparent);"
                    >
                      <span
                        class="text-xl font-bold font-mono tracking-[0.25em] shimmer-text"
                        style="color: var(--accent-1)"
                      >
                        ●●●●
                      </span>
                      <svg
                        class="w-3.5 h-3.5 opacity-40"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                        />
                      </svg>
                    </div>
                    <p
                      class="text-[9px] uppercase tracking-widest mt-1 opacity-30"
                      style="color: var(--color-text-dim)"
                    >
                      Tap to unlock
                    </p>
                  </div>

                  <div class="flex gap-2">
                    <button
                      phx-click="open_modal"
                      class="flex-1 py-2.5 rounded-xl font-semibold text-xs border transition-all active:scale-95 flex items-center justify-center gap-1.5"
                      style="border-color: color-mix(in srgb, var(--accent-1) 40%, transparent); color: var(--accent-1);"
                    >
                      <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                        />
                      </svg>
                      Message
                    </button>
                    <button
                      phx-click="open_modal"
                      class="flex-1 py-2.5 rounded-xl font-semibold text-xs text-white transition-all active:scale-95 flex items-center justify-center gap-1.5 shadow-lg"
                      style="background: linear-gradient(135deg, var(--accent-1), var(--accent-2));"
                    >
                      <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
                        />
                      </svg>
                      Save
                    </button>
                  </div>
                </div>
              </div>
            </div>
          <% end %>

          <%= if index == 4 do %>
            <div class="absolute inset-0 z-30 flex items-center justify-center p-6 paywall-slide">
              <div
                class="absolute inset-0 backdrop-blur-xl"
                style="background: color-mix(in srgb, var(--color-bg) 60%, transparent);"
              >
              </div>
              <div class="relative glass-panel rounded-3xl p-8 md:p-10 max-w-md w-full text-center border shadow-2xl float-anim">
                <div
                  class="w-16 h-16 rounded-full mx-auto mb-5 flex items-center justify-center border"
                  style="border-color: color-mix(in srgb, var(--accent-1) 30%, transparent); background: color-mix(in srgb, var(--accent-1) 8%, transparent); box-shadow: 0 0 20px color-mix(in srgb, var(--accent-1) 15%, transparent);"
                >
                  <svg
                    class="w-8 h-8"
                    style="color: var(--accent-1)"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="1.5"
                      d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                    />
                  </svg>
                </div>
                <h3
                  class="text-2xl md:text-3xl font-bold font-mono mb-2"
                  style="color: var(--color-text)"
                >
                  12 more homes hidden
                </h3>
                <p
                  class="text-sm md:text-base mb-8 leading-relaxed"
                  style="color: var(--color-text-dim)"
                >
                  Create a free account to unlock prices, contact owners directly, and save your favorite properties.
                </p>
                <button
                  phx-click="open_modal"
                  class="w-full py-4 rounded-xl font-bold text-sm md:text-base text-white transition-all hover:scale-[1.02] active:scale-95"
                  style="background: linear-gradient(135deg, var(--accent-1), var(--accent-2)); box-shadow: 0 0 25px color-mix(in srgb, var(--accent-1) 20%, transparent);"
                >
                  Unlock Full Access — 10 sec signup
                </button>
                <p class="text-xs mt-4 opacity-30" style="color: var(--color-text-dim)">
                  No credit card required
                </p>
              </div>
            </div>
          <% end %>

          <%= if index > 4 do %>
            <div class="absolute inset-0 z-20 flex items-center justify-center">
              <span
                class="text-sm font-mono font-bold tracking-[0.3em] opacity-20 border border-current px-4 py-2 rounded-lg"
                style="color: var(--color-text)"
              >
                ENCRYPTED
              </span>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>

    <style>
      .house-finder {
        --color-bg: #f4f6f8;
        --color-grid: rgba(0,0,0,0.04);
        --color-text: #0a0a1a;
        --color-text-dim: #5a5a70;
        --accent-1: #0055ff;
        --accent-2: #ff0099;
        --glass-bg: rgba(255,255,255,0.72);
        --glass-bg-strong: rgba(255,255,255,0.9);
        --glass-border: rgba(255,255,255,0.9);
        position: fixed;
        inset: 0;
        font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        background: var(--color-bg);
      }
      .house-finder.dark-theme {
        --color-bg: #020204;
        --color-grid: rgba(0,240,255,0.03);
        --color-text: #e8e8f0;
        --color-text-dim: #7777aa;
        --accent-1: #00f0ff;
        --accent-2: #bc13fe;
        --glass-bg: rgba(8,8,14,0.55);
        --glass-bg-strong: rgba(8,8,14,0.85);
        --glass-border: rgba(255,255,255,0.06);
        background: var(--color-bg);
      }
      .grid-bg {
        background-image:
          linear-gradient(var(--color-grid) 1px, transparent 1px),
          linear-gradient(90deg, var(--color-grid) 1px, transparent 1px);
        background-size: 60px 60px;
      }
      .scanlines::after {
        content: "";
        position: absolute;
        inset: 0;
        background: repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,0.2) 2px, rgba(0,0,0,0.2) 4px);
        pointer-events: none;
      }
      .glass-panel {
        background: var(--glass-bg);
        backdrop-filter: blur(20px);
        -webkit-backdrop-filter: blur(20px);
        border: 1px solid var(--glass-border);
        box-shadow: 0 8px 32px 0 rgba(0,0,0,0.12);
      }
      .dark-theme .glass-panel {
        box-shadow: 0 8px 32px 0 rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.04);
      }
      .note-overlay-card {
        background: linear-gradient(135deg, rgba(0,0,0,0.62), rgba(0,0,0,0.36));
        border-color: rgba(255,255,255,0.16);
        backdrop-filter: blur(18px) saturate(145%);
        -webkit-backdrop-filter: blur(18px) saturate(145%);
      }
      .house-section {
        height: 100vh;
        width: 100%;
        scroll-snap-align: start;
        flex-shrink: 0;
        position: relative;
      }
      .top-tab-active {
        background: color-mix(in srgb, var(--accent-1) 15%, transparent);
        color: var(--accent-1);
        box-shadow: 0 0 15px color-mix(in srgb, var(--accent-1) 20%, transparent), inset 0 1px 0 rgba(255,255,255,0.1);
        border: 1px solid color-mix(in srgb, var(--accent-1) 30%, transparent);
      }
      .top-tab-inactive {
        color: var(--color-text-dim);
        border: 1px solid transparent;
      }
      .top-tab-inactive:hover {
        background: color-mix(in srgb, var(--color-text) 5%, transparent);
        color: var(--color-text);
      }
      .bottom-nav-glass {
        background: var(--glass-bg);
        backdrop-filter: blur(24px) saturate(180%);
        -webkit-backdrop-filter: blur(24px) saturate(180%);
        border: 1px solid var(--glass-border);
      }
      .bottom-nav-item {
        color: color-mix(in srgb, var(--color-text) 82%, var(--accent-1));
        transition: all 0.2s ease;
      }
      .bottom-nav-item[style*="--accent-1"] {
        color: var(--accent-1);
      }
      .bottom-nav-icon {
        border-radius: 9999px;
        filter: drop-shadow(0 0 8px color-mix(in srgb, currentColor 35%, transparent));
        stroke-width: 2.2;
      }
      .bottom-nav-item:active {
        transform: scale(0.92);
      }
      .settings-sheet {
        animation: sheet-up 0.35s cubic-bezier(0.16, 1, 0.3, 1) forwards;
      }
      @keyframes sheet-up {
        from { transform: translateY(100%); }
        to { transform: translateY(0); }
      }
      .bg-blur-rich {
        filter: blur(8px) saturate(1.4) brightness(0.7);
        transform: scale(1.15);
      }
      .color-veil {
        background: linear-gradient(135deg, color-mix(in srgb, var(--accent-1) 8%, transparent) 0%, transparent 50%, color-mix(in srgb, var(--accent-2) 8%, transparent) 100%);
        mix-blend-mode: overlay;
      }
      .dark-theme .color-veil {
        background: linear-gradient(135deg, color-mix(in srgb, var(--accent-1) 12%, transparent) 0%, transparent 50%, color-mix(in srgb, var(--accent-2) 12%, transparent) 100%);
      }
      .hero-grid-floor {
        background-image:
          linear-gradient(var(--color-grid) 1px, transparent 1px),
          linear-gradient(90deg, var(--color-grid) 1px, transparent 1px);
        background-size: 40px 40px;
        transform: perspective(500px) rotateX(60deg);
        transform-origin: bottom center;
        mask-image: linear-gradient(to top, rgba(0,0,0,0.6), transparent);
        -webkit-mask-image: linear-gradient(to top, rgba(0,0,0,0.6), transparent);
      }
      .hologram-frame {
        transform-style: preserve-3d;
        animation: holo-float 6s ease-in-out infinite;
      }
      .hologram-screen {
        background: rgba(0,0,0,0.3);
      }
      .hologram-scanline {
        background: repeating-linear-gradient(0deg, transparent, transparent 3px, rgba(0,240,255,0.03) 3px, rgba(0,240,255,0.03) 6px);
        animation: scanline-move 8s linear infinite;
      }
      .holo-slide {
        position: absolute;
        inset: 0;
        width: 100%;
        height: 100%;
        object-fit: cover;
        opacity: 0;
        transition: opacity 1.2s ease-in-out, transform 8s ease-out;
        transform: scale(1);
      }
      .holo-slide.active {
        opacity: 1;
        transform: scale(1.08);
      }
      .location-pill {
        animation: fade-up 0.8s ease-out 0.3s both;
      }
      .particle {
        position: absolute;
        width: 3px;
        height: 3px;
        border-radius: 50%;
        background: var(--accent-1);
        opacity: 0;
        animation: particle-rise 4s ease-in-out infinite;
        box-shadow: 0 0 6px var(--accent-1);
      }
      @keyframes holo-float {
        0%, 100% { transform: translateY(0px) rotateX(2deg); }
        50% { transform: translateY(-12px) rotateX(-1deg); }
      }
      @keyframes scanline-move {
        0% { background-position: 0 0; }
        100% { background-position: 0 100px; }
      }
      @keyframes fade-up {
        from { opacity: 0; transform: translateY(15px); }
        to { opacity: 1; transform: translateY(0); }
      }
      @keyframes particle-rise {
        0% { opacity: 0; transform: translateY(0) scale(0); }
        20% { opacity: 0.6; }
        80% { opacity: 0.6; }
        100% { opacity: 0; transform: translateY(-120px) scale(1); }
      }
      @keyframes bounce-slow {
        0%, 100% { transform: translateY(0); }
        50% { transform: translateY(8px); }
      }
      .animate-bounce-slow {
        animation: bounce-slow 2.5s ease-in-out infinite;
      }
      @keyframes shimmer-soft {
        0%, 100% { opacity: 0.25; }
        50% { opacity: 0.65; text-shadow: 0 0 8px color-mix(in srgb, var(--accent-1) 25%, transparent); }
      }
      .shimmer-text {
        animation: shimmer-soft 4s ease-in-out infinite;
      }
      @keyframes float {
        0%, 100% { transform: translateY(0px); }
        50% { transform: translateY(-8px); }
      }
      .float-anim {
        animation: float 5s ease-in-out infinite;
      }
      @keyframes slideUp {
        from { transform: translateY(40px); opacity: 0; }
        to { transform: translateY(0); opacity: 1; }
      }
      .paywall-slide {
        animation: slideUp 0.7s cubic-bezier(0.16, 1, 0.3, 1) forwards;
      }
    </style>
    """
  end

  def render_help(assigns) do
    ~H"""
    <div class="fixed inset-0 grid-bg pointer-events-none z-0"></div>
    <div class={[
      "fixed inset-0 pointer-events-none z-0",
      if(@theme == "dark", do: "scanlines", else: "")
    ]}>
    </div>

    <div class="fixed top-4 left-4 z-50 flex items-center gap-2" id="help-brand">
      <span
        class="w-2 h-2 rounded-full animate-pulse"
        style="background: var(--accent-1); box-shadow: 0 0 10px var(--accent-1)"
      >
      </span>
      <span class="text-sm font-bold font-mono tracking-[0.3em]" style="color: var(--color-text)">
        HOME
      </span>
    </div>

    <main
      id="help-view"
      class="relative z-10 min-h-screen flex items-center justify-center px-5 py-24"
    >
      <section class="glass-panel w-full max-w-2xl rounded-3xl p-6 md:p-8">
        <div class="flex items-start justify-between gap-4 mb-6">
          <div>
            <p
              class="text-xs font-mono uppercase tracking-[0.24em] mb-2"
              style="color: var(--accent-1)"
            >
              Help
            </p>
            <h1
              class="text-2xl md:text-4xl font-bold font-mono leading-tight"
              style="color: var(--color-text)"
            >
              How HOME keeps property discovery private.
            </h1>
          </div>
          <button
            id="help-back-button"
            phx-click="set_view"
            phx-value-view="main"
            class="shrink-0 rounded-full border px-4 py-2 text-xs font-bold transition-all hover:scale-[1.02] active:scale-95"
            style="border-color: color-mix(in srgb, var(--accent-1) 35%, transparent); color: var(--accent-1)"
          >
            Back
          </button>
        </div>

        <div class="grid gap-3 md:grid-cols-3">
          <div
            class="rounded-2xl border p-4"
            style="border-color: var(--glass-border); background: color-mix(in srgb, var(--color-bg) 76%, transparent);"
          >
            <h2 class="text-sm font-bold font-mono mb-2" style="color: var(--color-text)">Unlock</h2>
            <p class="text-xs leading-relaxed" style="color: var(--color-text-dim)">
              Tap a hidden price or action to create an account and request access.
            </p>
          </div>
          <div
            class="rounded-2xl border p-4"
            style="border-color: var(--glass-border); background: color-mix(in srgb, var(--color-bg) 76%, transparent);"
          >
            <h2 class="text-sm font-bold font-mono mb-2" style="color: var(--color-text)">Verify</h2>
            <p class="text-xs leading-relaxed" style="color: var(--color-text-dim)">
              Owners approve requests before exact addresses and direct contacts are shared.
            </p>
          </div>
          <div
            class="rounded-2xl border p-4"
            style="border-color: var(--glass-border); background: color-mix(in srgb, var(--color-bg) 76%, transparent);"
          >
            <h2 class="text-sm font-bold font-mono mb-2" style="color: var(--color-text)">Save</h2>
            <p class="text-xs leading-relaxed" style="color: var(--color-text-dim)">
              Keep promising homes on your board and compare them when you are ready.
            </p>
          </div>
        </div>
      </section>
    </main>
    """
  end
end
