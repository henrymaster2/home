defmodule HomeWeb.Components.HouseCardComponent do
  use HomeWeb, :live_component

  def render(assigns) do
    houses_key = assigns.houses |> Enum.map(& &1.id) |> Enum.join(",")
    assigns = assign(assigns, :houses_key, houses_key)

    ~H"""
    <div
      id={"house-card-#{@id}"}
      phx-hook="HouseCardCycle"
      data-houses-key={@houses_key}
      class="relative w-full rounded-3xl overflow-hidden bg-slate-900 border border-white/10 shadow-2xl group flex flex-col justify-between h-[480px] transition-all duration-300 hover:border-amber-400/40"
    >
      <%= for house <- @houses do %>
        <div data-house={house.id} class="absolute inset-0 flex flex-col justify-between opacity-0 transition-opacity duration-700 ease-in-out">

          <div class="absolute inset-0 z-0">
            <%= for {img_url, index} <- Enum.with_index(house.images) do %>
              <div
                data-house-image={index}
                class="absolute inset-0 bg-cover bg-center opacity-0 transition-opacity duration-700 ease-in-out"
                style={"background-image: url('#{img_url}');"}
              ></div>
            <% end %>
            <div class="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/20 to-slate-950/60"></div>
          </div>

          <div class="relative z-10 p-6 flex flex-col gap-3">
            <div class="flex items-center justify-between">
              <span class="px-3 py-1 rounded-full bg-amber-400/10 border border-amber-400/30 text-amber-400 text-xs font-bold uppercase tracking-wider backdrop-blur-md">
                <%= house.type %>
              </span>
              <span class="text-xs font-mono text-slate-300 bg-slate-950/60 backdrop-blur-md px-3 py-1 rounded-full border border-white/10">
                <%= house.location %>
              </span>
            </div>

            <h3 class="text-2xl font-black text-white tracking-tight drop-shadow-md">
              <%= house.name %>
            </h3>

            <div class="flex gap-1.5 w-full pt-1">
              <%= for {_, index} <- Enum.with_index(house.images) do %>
                <div class="h-1 flex-1 bg-white/20 rounded-full overflow-hidden backdrop-blur-md">
                  <div data-house-progress={index} class="h-full bg-amber-400 shadow-[0_0_8px_#fbbf24]" style="width: 0%;"></div>
                </div>
              <% end %>
            </div>
          </div>

          <div class="relative z-10 p-6 flex flex-col gap-4">
            <div class="flex flex-wrap gap-1.5">
              <%= for spec <- house.specs do %>
                <span class="text-[11px] font-medium px-2.5 py-1 rounded-lg bg-slate-950/60 border border-white/10 text-slate-300 backdrop-blur-md">
                  <%= spec %>
                </span>
              <% end %>
            </div>

            <div class="flex items-center justify-between pt-2 border-t border-white/10">
              <div>
                <p class="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Monthly Rent</p>
                <p class="text-xl font-black text-amber-400"><%= house.price %></p>
              </div>
              <button class="px-4 py-2.5 bg-amber-400 hover:bg-amber-300 text-slate-950 text-xs font-extrabold uppercase tracking-wider rounded-xl transition-all shadow-lg active:scale-95">
                View Details
              </button>
            </div>
          </div>

        </div>
      <% end %>
    </div>
    """
  end
end
