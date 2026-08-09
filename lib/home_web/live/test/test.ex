defmodule HomeWeb.Text.Test do
  use HomeWeb, :live_view

  def mount(_params, _session, socket) do
    slides = [
      %{
        id: 1,
        url: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80",
        part_name: "Gourmet Kitchen",
        title: "Chef-Grade Culinary Space",
        specs: ["Quartz Island", "Matte Cabinetry", "Smart Ovens"],
        description: "Engineered for high-end hospitality with touch-to-open storage, ambient lighting, and direct patio counter passes."
      },
      %{
        id: 2,
        url: "https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=1200&q=80",
        part_name: "Living Lounge",
        title: "Seamless Indoor-Outdoor Flow",
        specs: ["White Oak Flooring", "Floor Glazing", "Acoustic Slate"],
        description: "Panoramic vistas framed by minimalist recessed profiles. Perimeter LED lighting tracks synchronize with natural sunlight."
      },
      %{
        id: 3,
        url: "https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=1200&q=80",
        part_name: "Master Suite",
        title: "Private Architectural Sanctuary",
        specs: ["Glass En-Suite", "Motorized Shades", "Walk-in Dressing"],
        description: "Designed for deep rest with soundproofed structural cavity layering and intelligent dynamic climate zoning."
      }
    ]

    {:ok,
     socket
     |> Phoenix.Component.assign(:live_module, __MODULE__)
     |> Phoenix.Component.assign(:slides, slides),
     layout: false}
  end

  def render(assigns) do
    ~H"""
    <div
      id="house-hero-container"
      phx-hook="HouseSlideshow"
      class="fixed inset-0 w-screen h-screen overflow-hidden bg-slate-950 font-sans text-white select-none z-[99999]"
    >
      <!-- DYNAMIC BLURRED GLASS BACKGROUND LAYER -->
      <div class="absolute inset-0 z-0 pointer-events-none">
        <%= for {slide, index} <- Enum.with_index(@slides) do %>
          <div
            data-bg={index}
            class="absolute inset-0 bg-cover bg-center transition-opacity duration-1000 ease-in-out scale-110 blur-3xl opacity-0 brightness-90 contrast-125"
            style={"background-image: url('#{slide.url}');"}
          ></div>
        <% end %>
        <!-- Dark Ambient Glass Tint -->
        <div class="absolute inset-0 bg-slate-950/50 backdrop-blur-2xl"></div>
        <div class="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/20 to-slate-950/80"></div>
      </div>

      <!-- TOP BRANDING & HIGH-TECH PROGRESS BARS -->
      <div class="absolute top-0 left-0 right-0 z-50 px-8 py-6 flex flex-col gap-4 bg-gradient-to-b from-slate-950/90 to-transparent">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-2.5 h-2.5 rounded-full bg-amber-400 shadow-[0_0_14px_#fbbf24] animate-pulse"></div>
            <span class="text-xs font-black tracking-widest uppercase text-slate-200">Architectural Showcase</span>
          </div>
          <span class="text-[11px] font-mono text-slate-400 bg-slate-900/60 backdrop-blur-xl px-3 py-1 rounded-full border border-white/10">
            Neural Vision Mode
          </span>
        </div>

        <!-- Sync Progress Lines -->
        <div class="flex gap-2 w-full max-w-xl mx-auto">
          <%= for {_, index} <- Enum.with_index(@slides) do %>
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

      <!-- MAIN LAYOUT (TEXT TOP-LEFT, FLOATING BORDERLESS PHOTO RIGHT) -->
      <div class="relative z-20 w-full h-full flex flex-col lg:flex-row items-center justify-between px-8 lg:px-20 pt-28 pb-20 gap-8">

        <!-- TOP-LEFT FLOATING EXPLANATION LAYER (Sliding from Top-Left) -->
        <div class="w-full lg:w-5/12 h-full flex flex-col justify-center relative">
          <%= for {slide, index} <- Enum.with_index(@slides) do %>
            <div
              data-text={index}
              class="absolute inset-0 flex flex-col justify-center transition-all duration-700 ease-[cubic-bezier(0.16,1,0.3,1)] opacity-0 -translate-x-12 -translate-y-8 pointer-events-none"
            >
              <!-- Glass Badge -->
              <div class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-400/10 border border-amber-400/30 text-amber-400 text-xs font-bold uppercase tracking-widest w-fit mb-4 backdrop-blur-xl shadow-[0_0_15px_rgba(251,191,36,0.15)]">
                <span class="w-1.5 h-1.5 rounded-full bg-amber-400 shadow-[0_0_6px_#fbbf24]"></span>
                <%= slide.part_name %>
              </div>

              <!-- Main Title -->
              <h2 class="text-4xl lg:text-5xl font-black text-white tracking-tight leading-tight mb-4 drop-shadow-2xl">
                <%= slide.title %>
              </h2>

              <!-- Specs Pills -->
              <div class="flex flex-wrap gap-2 mb-6">
                <%= for spec <- slide.specs do %>
                  <span class="text-xs font-semibold px-3 py-1.5 rounded-xl bg-slate-900/50 border border-white/10 text-slate-300 backdrop-blur-md shadow-lg">
                    <%= spec %>
                  </span>
                <% end %>
              </div>

              <!-- Glass Description Box -->
              <div class="p-6 rounded-2xl bg-slate-900/40 backdrop-blur-2xl border border-white/10 shadow-[0_20px_50px_rgba(0,0,0,0.5)] max-w-lg">
                <p class="text-sm text-slate-300 leading-relaxed font-light">
                  <%= slide.description %>
                </p>
              </div>
            </div>
          <% end %>
        </div>

        <!-- CENTER-RIGHT FLOATING BORDERLESS CUTOUT PHOTO -->
        <div class="w-full lg:w-7/12 h-full flex items-center justify-center relative">
          <%= for {slide, index} <- Enum.with_index(@slides) do %>
            <div
              data-slide={index}
              class="absolute w-full max-w-2xl h-[420px] lg:h-[500px] rounded-3xl overflow-hidden transition-all duration-700 ease-[cubic-bezier(0.16,1,0.3,1)] opacity-0 scale-95 translate-y-4 pointer-events-none shadow-[0_30px_90px_rgba(0,0,0,0.95)]"
            >
              <img
                src={slide.url}
                alt={slide.part_name}
                class="w-full h-full object-cover rounded-3xl"
              />
              <!-- Soft Internal Vignette Shading (No Borders) -->
              <div class="absolute inset-0 bg-gradient-to-t from-slate-950/50 via-transparent to-black/10 rounded-3xl"></div>
            </div>
          <% end %>
        </div>

      </div>

      <!-- BOTTOM ACTION BAR -->
      <div class="absolute bottom-6 left-8 right-8 z-40 flex items-center justify-between border-t border-white/10 bg-slate-950/40 backdrop-blur-xl px-6 py-4 rounded-2xl shadow-2xl">
        <div>
          <p class="text-xs uppercase font-medium tracking-wider text-slate-400">Est. Property Value</p>
          <p class="text-xl font-extrabold text-amber-400 tracking-tight">$1,250,000</p>
        </div>
        <button class="px-6 py-3 bg-gradient-to-r from-amber-500 to-amber-400 hover:from-amber-400 hover:to-amber-300 text-slate-950 text-xs font-black uppercase tracking-wider rounded-xl transition-all duration-300 shadow-[0_0_20px_rgba(245,158,11,0.3)] active:scale-95">
          Schedule Private Tour
        </button>
      </div>

    </div>
    """
  end
end
