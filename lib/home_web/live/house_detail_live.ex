defmodule HomeWeb.HouseDetailLive do
  use HomeWeb, :live_view

  # --------------------------------------------------------------------
  # TEMP DATA LAYER
  # Replace this with a real context call, e.g.:
  #   Home.Listings.get_house!(id)
  # Keeping it inline for now so the LiveView is drop-in runnable.
  # --------------------------------------------------------------------
  @houses %{
    "1" => %{
      id: "1",
      name: "The Meridian Residence",
      type: "Villa",
      location: "Nakuru, KE",
      price: "$1,250,000",
      rooms: [
        %{
          id: 1,
          url: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80",
          part_name: "Gourmet Kitchen",
          title: "Chef-Grade Culinary Space",
          specs: ["Quartz Island", "Matte Cabinetry", "Smart Ovens"],
          description:
            "Engineered for high-end hospitality with touch-to-open storage, ambient lighting, and direct patio counter passes."
        },
        %{
          id: 2,
          url: "https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80",
          part_name: "Living Lounge",
          title: "Seamless Indoor-Outdoor Flow",
          specs: ["White Oak Flooring", "Floor Glazing", "Acoustic Slate"],
          description:
            "Panoramic vistas framed by minimalist recessed profiles. Perimeter LED lighting tracks synchronize with natural sunlight."
        },
        %{
          id: 3,
          url: "https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=80",
          part_name: "Master Suite",
          title: "Private Architectural Sanctuary",
          specs: ["Glass En-Suite", "Motorized Shades", "Walk-in Dressing"],
          description:
            "Designed for deep rest with soundproofed structural cavity layering and intelligent dynamic climate zoning."
        }
      ]
    }
  }

  defp get_house(id), do: Map.fetch(@houses, id)

  # --------------------------------------------------------------------
  # LIFECYCLE
  # --------------------------------------------------------------------
  def mount(%{"id" => id}, _session, socket) do
    case get_house(id) do
      {:ok, house} ->
        {:ok,
         socket
         |> assign(:house, house)
         |> assign(:rooms, house.rooms)
         |> assign(:page_title, house.name),
         layout: false}

      :error ->
        {:ok,
         socket
         |> put_flash(:error, "That listing could not be located in the grid.")
         |> push_navigate(to: ~p"/houses"),
         layout: false}
    end
  end

  # --------------------------------------------------------------------
  # RENDER
  # --------------------------------------------------------------------
  def render(assigns) do
    ~H"""
    <div
      id={"house-hero-#{@house.id}"}
      phx-hook="HouseSlideshow"
      class="fixed inset-0 w-screen h-screen overflow-hidden bg-slate-950 font-sans text-white select-none z-[99999]"
    >
      <style>
        @keyframes scanline-sweep {
          0% { transform: translateY(-100%); opacity: 0; }
          10% { opacity: 0.6; }
          90% { opacity: 0.6; }
          100% { transform: translateY(100vh); opacity: 0; }
        }
        @keyframes grid-drift {
          0% { background-position: 0 0; }
          100% { background-position: 64px 64px; }
        }
        @keyframes glitch-in {
          0% { clip-path: inset(0 0 100% 0); opacity: 0; transform: translateX(-6px); }
          40% { clip-path: inset(0 0 40% 0); opacity: 1; transform: translateX(3px); }
          60% { clip-path: inset(0 0 15% 0); transform: translateX(-1px); }
          100% { clip-path: inset(0 0 0 0); opacity: 1; transform: translateX(0); }
        }
        .scanline-sweep { animation: scanline-sweep 4.5s linear infinite; }
        .grid-drift {
          background-image:
            linear-gradient(rgba(251,191,36,0.06) 1px, transparent 1px),
            linear-gradient(90deg, rgba(251,191,36,0.06) 1px, transparent 1px);
          background-size: 64px 64px;
          animation: grid-drift 6s linear infinite;
        }
        .glitch-title { animation: glitch-in 0.6s cubic-bezier(0.16,1,0.3,1) both; }
      </style>

      <!-- AMBIENT GRID + BLURRED BACKGROUND LAYER -->
      <div class="absolute inset-0 z-0 pointer-events-none">
        <div class="absolute inset-0 grid-drift opacity-40"></div>
        <%= for {room, index} <- Enum.with_index(@rooms) do %>
          <div
            data-bg={index}
            class="absolute inset-0 bg-cover bg-center transition-opacity duration-1000 ease-in-out scale-110 blur-3xl opacity-0 brightness-90 contrast-125"
            style={"background-image: url('#{room.url}');"}
          ></div>
        <% end %>
        <div class="absolute inset-0 bg-slate-950/55 backdrop-blur-2xl"></div>
        <div class="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/20 to-slate-950/80"></div>
        <!-- Vertical scan sweep -->
        <div class="absolute inset-x-0 top-0 h-24 bg-gradient-to-b from-amber-300/20 to-transparent scanline-sweep"></div>
      </div>

      <!-- HUD CORNER BRACKETS -->
      <div class="absolute inset-6 z-40 pointer-events-none">
        <div class="absolute top-0 left-0 w-10 h-10 border-l-2 border-t-2 border-amber-400/60 rounded-tl-xl"></div>
        <div class="absolute top-0 right-0 w-10 h-10 border-r-2 border-t-2 border-amber-400/60 rounded-tr-xl"></div>
        <div class="absolute bottom-0 left-0 w-10 h-10 border-l-2 border-b-2 border-amber-400/60 rounded-bl-xl"></div>
        <div class="absolute bottom-0 right-0 w-10 h-10 border-r-2 border-b-2 border-amber-400/60 rounded-br-xl"></div>
      </div>

      <!-- TOP BRANDING / HUD READOUT -->
      <div class="absolute top-0 left-0 right-0 z-50 px-8 py-6 flex flex-col gap-4 bg-gradient-to-b from-slate-950/90 to-transparent">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <.link
              navigate={~p"/houses"}
              class="flex items-center gap-1.5 text-[11px] font-mono uppercase tracking-widest text-slate-400 hover:text-amber-400 transition-colors bg-slate-900/60 backdrop-blur-xl px-3 py-1.5 rounded-full border border-white/10"
            >
              &larr; Grid
            </.link>
            <div class="flex items-center gap-3">
              <div class="w-2.5 h-2.5 rounded-full bg-amber-400 shadow-[0_0_14px_#fbbf24] animate-pulse"></div>
              <span class="text-xs font-black tracking-widest uppercase text-slate-200">
                Neural Property Uplink
              </span>
            </div>
          </div>
          <span class="text-[11px] font-mono text-amber-300 bg-slate-900/60 backdrop-blur-xl px-3 py-1 rounded-full border border-amber-400/20">
            SYNC :: 100% &middot; ID-<%= @house.id %>
          </span>
        </div>

        <div class="flex gap-2 w-full max-w-xl mx-auto">
          <%= for {_, index} <- Enum.with_index(@rooms) do %>
            <div class="h-1 flex-1 bg-white/10 rounded-full overflow-hidden backdrop-blur-md">
              <div
                data-progress={index}
                class="h-full bg-gradient-to-r from-amber-400 to-amber-200 rounded-full shadow-[0_0_10px_rgba(251,191,36,0.8)] transition-all ease-linear"
                style="width: 0%;"
              ></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- MAIN LAYOUT -->
      <div class="relative z-20 w-full h-full flex flex-col lg:flex-row items-center justify-between px-8 lg:px-20 pt-32 pb-24 gap-8">

        <!-- TEXT PANEL -->
        <div class="w-full lg:w-5/12 h-full flex flex-col justify-center relative">
          <div class="mb-6">
            <p class="text-[11px] font-mono uppercase tracking-[0.3em] text-amber-400/80"><%= @house.type %> &middot; <%= @house.location %></p>
            <h1 class="glitch-title text-2xl lg:text-3xl font-black text-white tracking-tight mt-1"><%= @house.name %></h1>
          </div>

          <%= for {room, index} <- Enum.with_index(@rooms) do %>
            <div
              data-text={index}
              class="absolute inset-0 flex flex-col justify-center pt-20 transition-all duration-700 ease-[cubic-bezier(0.16,1,0.3,1)] opacity-0 -translate-x-12 -translate-y-8 pointer-events-none"
            >
              <div class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-400/10 border border-amber-400/30 text-amber-400 text-xs font-bold uppercase tracking-widest w-fit mb-4 backdrop-blur-xl shadow-[0_0_15px_rgba(251,191,36,0.15)]">
                <span class="w-1.5 h-1.5 rounded-full bg-amber-400 shadow-[0_0_6px_#fbbf24]"></span>
                <%= room.part_name %>
                <span class="text-slate-400 font-mono normal-case">
                  &middot; <%= String.pad_leading(to_string(index + 1), 2, "0") %>/<%= String.pad_leading(to_string(length(@rooms)), 2, "0") %>
                </span>
              </div>

              <h2 class="text-4xl lg:text-5xl font-black text-white tracking-tight leading-tight mb-4 drop-shadow-2xl">
                <%= room.title %>
              </h2>

              <div class="flex flex-wrap gap-2 mb-6">
                <%= for spec <- room.specs do %>
                  <span class="text-xs font-semibold px-3 py-1.5 rounded-xl bg-slate-900/50 border border-white/10 text-slate-300 backdrop-blur-md shadow-lg">
                    <%= spec %>
                  </span>
                <% end %>
              </div>

              <div class="p-6 rounded-2xl bg-slate-900/40 backdrop-blur-2xl border border-white/10 shadow-[0_20px_50px_rgba(0,0,0,0.5)] max-w-lg">
                <p class="text-[10px] font-mono uppercase tracking-widest text-amber-400/70 mb-2">AI Spatial Analysis</p>
                <p class="text-sm text-slate-300 leading-relaxed font-light">
                  <%= room.description %>
                </p>
              </div>
            </div>
          <% end %>
        </div>

        <!-- IMAGE PANEL -->
        <div class="w-full lg:w-7/12 h-full flex items-center justify-center relative">
          <%= for {room, index} <- Enum.with_index(@rooms) do %>
            <div
              data-slide={index}
              class="absolute w-full max-w-2xl h-[420px] lg:h-[500px] rounded-3xl overflow-hidden transition-all duration-700 ease-[cubic-bezier(0.16,1,0.3,1)] opacity-0 scale-95 translate-y-4 pointer-events-none shadow-[0_30px_90px_rgba(0,0,0,0.95)] ring-1 ring-amber-400/10"
            >
              <img src={room.url} alt={room.part_name} class="w-full h-full object-cover rounded-3xl" />
              <div class="absolute inset-0 bg-gradient-to-t from-slate-950/50 via-transparent to-black/10 rounded-3xl"></div>
              <!-- Corner readout on the image itself -->
              <div class="absolute top-4 right-4 text-[10px] font-mono uppercase tracking-widest text-amber-300/90 bg-slate-950/50 backdrop-blur-md px-2.5 py-1 rounded-md border border-amber-400/20">
                Optical Feed &middot; Live
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- BOTTOM ACTION BAR -->
      <div class="absolute bottom-6 left-8 right-8 z-40 flex items-center justify-between border-t border-white/10 bg-slate-950/40 backdrop-blur-xl px-6 py-4 rounded-2xl shadow-2xl">
        <div>
          <p class="text-[10px] uppercase font-mono tracking-widest text-slate-400">Valuation Index</p>
          <p class="text-xl font-extrabold text-amber-400 tracking-tight"><%= @house.price %></p>
        </div>
        <button class="px-6 py-3 bg-gradient-to-r from-amber-500 to-amber-400 hover:from-amber-400 hover:to-amber-300 text-slate-950 text-xs font-black uppercase tracking-wider rounded-xl transition-all duration-300 shadow-[0_0_20px_rgba(245,158,11,0.3)] active:scale-95">
          Initiate Virtual Walkthrough
        </button>
      </div>
    </div>
    """
  end
end
