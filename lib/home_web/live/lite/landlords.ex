defmodule HomeWeb.Lite.Landlords do
  use HomeWeb, :live_view

  alias Home.Accounts

  @mock_listings [
    %{
      title: "Modern 2-bedroom apartment",
      location: "Kilimani, Nairobi",
      price: "KES 65,000 / month",
      status: "Available"
    },
    %{
      title: "Furnished studio apartment",
      location: "Westlands, Nairobi",
      price: "KES 42,000 / month",
      status: "Available"
    },
    %{
      title: "Family townhouse",
      location: "Syokimau, Machakos",
      price: "KES 95,000 / month",
      status: "Occupied"
    }
  ]

  @registration_documents [
    {"id_front", "ID front", :id_front_url},
    {"id_back", "ID back", :id_back_url},
    {"kra_doc", "KRA PIN certificate", :kra_doc_url},
    {"ownership_doc", "Proof of ownership", :ownership_doc_url}
  ]

  @impl true
  def mount(_params, _session, socket) do
    landlords = Accounts.list_verified_landlords_with_documents()

    if connected?(socket) do
      Accounts.subscribe_admin_verifications()
    end

    {:ok,
     socket
     |> assign(:page_title, "Verified Landlords")
     |> assign(:landlords, landlords)
     |> assign(:selected_landlord, List.first(landlords))
     |> assign(:search_query, "")
     |> assign(:mobile_search_open, false)
     |> assign(:mobile_sidebar_open, false)
     |> assign(:active_right_tab, "details")
     |> assign(:mock_listings, @mock_listings)
     |> assign(:theme, "light")
     |> assign(:dark_mode, false)}
  end

  @impl true
  def handle_event("select_landlord", %{"id" => id}, socket) do
    selected = Enum.find(socket.assigns.landlords, &(to_string(&1.id) == id))

    {:noreply,
     socket
     |> assign(:selected_landlord, selected)
     |> assign(:mobile_search_open, false)
     |> assign(:mobile_sidebar_open, false)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, :search_query, query)}
  end

  def handle_event("toggle_mobile_search", _params, socket) do
    {:noreply, update(socket, :mobile_search_open, &(!&1))}
  end

  def handle_event("select_right_tab", %{"tab" => tab}, socket)
      when tab in ["details", "documents", "units"] do
    {:noreply, assign(socket, :active_right_tab, tab)}
  end

  def handle_event("toggle_mobile_sidebar", _params, socket) do
    {:noreply, update(socket, :mobile_sidebar_open, &(!&1))}
  end

  def handle_event("toggle_theme", _, socket) do
    new_theme =
      if socket.assigns.theme == "dark" do
        "light"
      else
        "dark"
      end

    {:noreply,
     socket
     |> assign(:theme, new_theme)
     |> assign(:dark_mode, new_theme == "dark")
     |> push_event("set_global_theme", %{theme: new_theme})}
  end

  @impl true
  def handle_event("restore_theme", %{"theme" => theme}, socket)
      when theme in ["dark", "light"] do
    {:noreply,
     socket
     |> assign(:theme, theme)
     |> assign(:dark_mode, theme == "dark")}
  end

  @impl true
  def handle_info({:admin_verification_updated, _landlord}, socket) do
    refresh_landlords(socket)
  end

  def handle_info({:landlord_message_updated, _landlord}, socket) do
    refresh_landlords(socket)
  end

  defp refresh_landlords(socket) do
    landlords = Accounts.list_verified_landlords_with_documents()
    selected_id = socket.assigns.selected_landlord && socket.assigns.selected_landlord.id
    selected_landlord = Enum.find(landlords, &(&1.id == selected_id)) || List.first(landlords)

    {:noreply, assign(socket, landlords: landlords, selected_landlord: selected_landlord)}
  end

  defp filtered_landlords(landlords, query) do
    query = String.downcase(String.trim(query))

    Enum.filter(landlords, fn landlord ->
      searchable =
        [
          landlord.names,
          landlord.email,
          landlord.phone,
          landlord.property_name,
          landlord.property_location
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(" ")
        |> String.downcase()

      query == "" or String.contains?(searchable, query)
    end)
  end

  defp initials(name) do
    name
    |> to_string()
    |> String.split(" ", trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
  end

  defp registration_entries(landlord) do
    saved_draft =
      case landlord.verification_request do
        %{draft_data: data} when is_map(data) -> data
        _ -> %{}
      end

    saved_landlord_fields = %{
      "subscription_plan" => landlord.subscription_plan,
      "billing_method" => landlord.billing_method,
      "billing_phone" => landlord.billing_phone,
      "enable_payouts" => landlord.enable_direct_payouts,
      "payout_method" => landlord.payout_method,
      "payout_number" => landlord.payout_number,
      "payout_name" => landlord.payout_name
    }

    saved_draft
    |> Map.merge(Map.reject(saved_landlord_fields, fn {_key, value} -> is_nil(value) end))
    |> Map.merge(landlord.registration_data || %{})
    |> Enum.reject(fn {key, _value} ->
      key in ["password", "password_confirmation"] or
        String.ends_with?(key, "_url") or String.ends_with?(key, "_meta")
    end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map(fn {key, value} ->
      %{
        label: key |> String.replace("_", " ") |> String.capitalize(),
        value: display_registration_value(value)
      }
    end)
  end

  defp display_registration_value(value) when value in [nil, ""], do: "Not provided"
  defp display_registration_value(true), do: "Yes"
  defp display_registration_value(false), do: "No"
  defp display_registration_value(value) when is_binary(value), do: value
  defp display_registration_value(value) when is_map(value), do: inspect(value)
  defp display_registration_value(value) when is_list(value), do: Enum.join(value, ", ")
  defp display_registration_value(value), do: to_string(value)

  defp submitted_documents(landlord) do
    Enum.flat_map(@registration_documents, fn {type, label, field} ->
      document = Enum.find(landlord.documents || [], &(&1.document_type == type))
      url = Map.get(landlord, field) || (document && document.file_url)

      if is_binary(url) and url != "" do
        [
          %{
            label: label,
            url: url,
            filename: (document && document.original_filename) || label,
            content_type: document && document.content_type
          }
        ]
      else
        []
      end
    end)
  end

  defp image_document?(document) do
    content_type = document.content_type || ""

    extension =
      document.url |> URI.parse() |> Map.get(:path, "") |> Path.extname() |> String.downcase()

    String.starts_with?(content_type, "image/") or
      extension in [".jpg", ".jpeg", ".png", ".webp", ".gif"]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} full_screen={true}>
      <div
        id="lite-landlords"
        phx-hook="HouseFinder"
        class={["flex min-h-screen flex-col font-sans", @theme == "dark" && "dark"]}
      >
        <div class={[
          "flex min-h-screen flex-col font-sans transition-colors",
          @theme == "dark" && "bg-slate-900 text-slate-100",
          @theme != "dark" && "bg-slate-50 text-slate-800"
        ]}>
          <!-- Header -->
          <header class={[
            "sticky top-0 z-30 border-b px-4 py-4 lg:px-8 transition-colors",
            @theme == "dark" && "border-slate-800 bg-slate-900 text-white",
            @theme != "dark" && "border-slate-200 bg-white text-slate-900"
          ]}>
            <div class="relative flex min-h-12 w-full items-center justify-center">
              <button
                id="toggle-landlords-sidebar"
                type="button"
                phx-click="toggle_mobile_sidebar"
                class={[
                  "absolute left-0 rounded-md p-2 transition-colors lg:hidden",
                  @theme == "dark" && "text-slate-400 hover:bg-slate-800",
                  @theme != "dark" && "text-slate-600 hover:bg-slate-100"
                ]}
                aria-label="Open landlord sidebar"
                aria-expanded={@mobile_sidebar_open}
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="size-6"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M10.5 6h9.75M10.5 6a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m-9.75 0h9.75"
                  />
                </svg>
              </button>
              <div class="max-w-[75vw] text-center">
                <h1 class={[
                  "text-2xl font-bold tracking-tight sm:text-3xl",
                  @theme == "dark" && "text-white",
                  @theme != "dark" && "text-slate-900"
                ]}>
                  Verified Landlords
                </h1>
                <p class={[
                  "mt-0.5 truncate text-xs sm:text-sm",
                  @theme == "dark" && "text-slate-400",
                  @theme != "dark" && "text-slate-500"
                ]}>
                  <%= if @selected_landlord do %>
                    Viewing:
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-indigo-400",
                      @theme != "dark" && "text-indigo-600"
                    ]}>
                      {@selected_landlord.names}
                    </span>
                  <% else %>
                    No verified landlords found
                  <% end %>
                </p>
              </div>
            </div>
          </header>

          <div class="flex w-full flex-1 overflow-hidden">
            <!-- Desktop Sidebar -->
            <aside class={[
              "hidden w-80 shrink-0 flex-col overflow-y-auto border-r lg:flex xl:w-96 transition-colors",
              @theme == "dark" && "border-slate-800 bg-slate-900",
              @theme != "dark" && "border-slate-200 bg-white"
            ]}>
              <div class="flex-1 p-4">
                <form phx-change="search" class="relative mb-4">
                  <.icon
                    name="hero-magnifying-glass"
                    class={[
                      "absolute left-3 top-2.5 size-4",
                      @theme == "dark" && "text-slate-500",
                      @theme != "dark" && "text-slate-400"
                    ]}
                  />
                  <input
                    id="desktop-verified-landlord-search"
                    type="search"
                    name="query"
                    value={@search_query}
                    placeholder="Search landlords..."
                    class={[
                      "w-full rounded-lg border py-2 pl-9 pr-3 text-sm focus:outline-none focus:ring-2",
                      @theme == "dark" &&
                        "border-slate-700 bg-slate-800 text-slate-100 placeholder-slate-400 focus:border-indigo-500 focus:ring-indigo-500/20",
                      @theme != "dark" &&
                        "border-slate-200 bg-slate-50 text-slate-800 focus:border-indigo-500 focus:bg-white focus:ring-indigo-500/20"
                    ]}
                  />
                </form>
                <h2 class={[
                  "mb-3 text-xs font-semibold uppercase tracking-wider",
                  @theme == "dark" && "text-slate-500",
                  @theme != "dark" && "text-slate-400"
                ]}>
                  Landlords ({length(filtered_landlords(@landlords, @search_query))})
                </h2>
                <div class="space-y-2">
                  <.landlord_option
                    :for={landlord <- filtered_landlords(@landlords, @search_query)}
                    landlord={landlord}
                    selected={@selected_landlord && @selected_landlord.id == landlord.id}
                    dark_mode={@dark_mode}
                  />
                  <p
                    :if={filtered_landlords(@landlords, @search_query) == []}
                    class={[
                      "px-3 py-8 text-center text-sm",
                      @theme == "dark" && "text-slate-400",
                      @theme != "dark" && "text-slate-500"
                    ]}
                  >
                    No matching verified landlords.
                  </p>
                </div>
              </div>
              
    <!-- Dark/Light Mode Toggle Button at the bottom of sidebar -->
              <div class={[
                "border-t p-4 transition-colors",
                @theme == "dark" && "border-slate-800",
                @theme != "dark" && "border-slate-200"
              ]}>
                <button
                  type="button"
                  phx-click="toggle_theme"
                  class={[
                    "flex w-full items-center justify-center gap-2 rounded-lg border px-4 py-2.5 text-xs font-semibold transition",
                    @theme == "dark" &&
                      "border-slate-700 bg-slate-800 text-slate-200 hover:bg-slate-700",
                    @theme != "dark" &&
                      "border-slate-200 bg-slate-50 text-slate-700 hover:bg-slate-100"
                  ]}
                >
                  <.icon :if={!@dark_mode} name="hero-moon" class="size-4 text-slate-500" />
                  <.icon :if={@dark_mode} name="hero-sun" class="size-4 text-amber-400" />
                  <span>
                    {if @dark_mode, do: "Switch to Light Mode", else: "Switch to Dark Mode"}
                  </span>
                </button>
              </div>
            </aside>
            
    <!-- Mobile Sidebar -->
            <div :if={@mobile_sidebar_open} class="fixed inset-0 z-40 flex lg:hidden">
              <button
                type="button"
                phx-click="toggle_mobile_sidebar"
                class="fixed inset-0 bg-slate-900/40 backdrop-blur-sm"
                aria-label="Close landlord list"
              >
              </button>
              <aside class={[
                "relative z-10 flex h-full w-4/5 max-w-xs flex-col shadow-xl transition-colors",
                @theme == "dark" && "bg-slate-900 text-white",
                @theme != "dark" && "bg-white text-slate-900"
              ]}>
                <div class={[
                  "flex items-center justify-between border-b p-4",
                  @theme == "dark" && "border-slate-800",
                  @theme != "dark" && "border-slate-200"
                ]}>
                  <h2 class="text-sm font-semibold">Select landlord</h2>
                  <div class="flex items-center gap-2">
                    <button
                      id="toggle-mobile-landlord-search"
                      type="button"
                      phx-click="toggle_mobile_search"
                      class={[
                        "rounded-md p-2 transition-colors",
                        @theme == "dark" && "text-slate-300 hover:bg-slate-800",
                        @theme != "dark" && "text-slate-600 hover:bg-slate-100"
                      ]}
                      aria-label={
                        if(@mobile_search_open, do: "Close search", else: "Search landlords")
                      }
                      aria-expanded={@mobile_search_open}
                    >
                      <.icon
                        name={
                          if(@mobile_search_open, do: "hero-x-mark", else: "hero-magnifying-glass")
                        }
                        class="size-5"
                      />
                    </button>
                    <button
                      type="button"
                      phx-click="toggle_mobile_sidebar"
                      class="rounded-md p-1 text-slate-400 hover:text-slate-600"
                      aria-label="Close landlord list"
                    >
                      <.icon name="hero-x-mark" class="size-5" />
                    </button>
                  </div>
                </div>
                <form :if={@mobile_search_open} phx-change="search" class="relative px-3 pt-3">
                  <.icon
                    name="hero-magnifying-glass"
                    class={[
                      "absolute left-6 top-5 size-4",
                      @theme == "dark" && "text-slate-500",
                      @theme != "dark" && "text-slate-400"
                    ]}
                  />
                  <input
                    id="mobile-verified-landlord-search"
                    type="search"
                    name="query"
                    value={@search_query}
                    placeholder="Search landlords..."
                    autofocus
                    class={[
                      "w-full rounded-lg border py-2 pl-9 pr-3 text-sm focus:outline-none focus:ring-2",
                      @theme == "dark" &&
                        "border-slate-700 bg-slate-800 text-slate-100 placeholder-slate-400 focus:border-indigo-500 focus:ring-indigo-500/20",
                      @theme != "dark" &&
                        "border-slate-200 bg-slate-50 text-slate-800 focus:border-indigo-500 focus:bg-white focus:ring-indigo-500/20"
                    ]}
                  />
                </form>
                <div class="flex-1 space-y-2 overflow-y-auto p-3">
                  <.landlord_option
                    :for={landlord <- filtered_landlords(@landlords, @search_query)}
                    landlord={landlord}
                    selected={@selected_landlord && @selected_landlord.id == landlord.id}
                    dark_mode={@dark_mode}
                  />
                </div>
                <div class={[
                  "border-t p-4",
                  @theme == "dark" && "border-slate-800",
                  @theme != "dark" && "border-slate-200"
                ]}>
                  <button
                    type="button"
                    phx-click="toggle_theme"
                    class={[
                      "flex w-full items-center justify-center gap-2 rounded-lg border px-4 py-2.5 text-xs font-semibold transition",
                      @theme == "dark" &&
                        "border-slate-700 bg-slate-800 text-slate-200 hover:bg-slate-700",
                      @theme != "dark" &&
                        "border-slate-200 bg-slate-50 text-slate-700 hover:bg-slate-100"
                    ]}
                  >
                    <.icon :if={@theme != "dark"} name="hero-moon" class="size-4 text-slate-500" />
                    <.icon :if={@theme == "dark"} name="hero-sun" class="size-4 text-amber-400" />
                    <span>
                      {if @theme == "dark", do: "Switch to Light Mode", else: "Switch to Dark Mode"}
                    </span>
                  </button>
                </div>
              </aside>
            </div>
            
    <!-- Main Content Area -->
            <main class="flex-1 overflow-y-auto p-4 md:p-8">
              <%= if @selected_landlord do %>
                <div class="w-full space-y-6">
                  <div
                    class={[
                      "flex gap-2 border-b",
                      @theme == "dark" && "border-slate-800",
                      @theme != "dark" && "border-slate-200"
                    ]}
                    role="tablist"
                    aria-label="Landlord information"
                  >
                    <button
                      id="landlord-details-tab"
                      type="button"
                      role="tab"
                      aria-selected={@active_right_tab == "details"}
                      phx-click="select_right_tab"
                      phx-value-tab="details"
                      class={[
                        "px-4 py-3 text-sm font-medium transition",
                        @active_right_tab == "details" &&
                          if(@theme == "dark",
                            do: "border-b-2 border-indigo-500 font-semibold text-indigo-400",
                            else: "border-b-2 border-indigo-600 font-semibold text-indigo-700"
                          ),
                        @active_right_tab != "details" &&
                          if(@theme == "dark",
                            do: "text-slate-400 hover:text-slate-200",
                            else: "text-slate-500 hover:text-slate-800"
                          )
                      ]}
                    >
                      Landlord details
                    </button>
                    <button
                      id="landlord-documents-tab"
                      type="button"
                      role="tab"
                      aria-selected={@active_right_tab == "documents"}
                      phx-click="select_right_tab"
                      phx-value-tab="documents"
                      class={[
                        "px-4 py-3 text-sm font-medium transition",
                        @active_right_tab == "documents" &&
                          if(@theme == "dark",
                            do: "border-b-2 border-indigo-500 font-semibold text-indigo-400",
                            else: "border-b-2 border-indigo-600 font-semibold text-indigo-700"
                          ),
                        @active_right_tab != "documents" &&
                          if(@theme == "dark",
                            do: "text-slate-400 hover:text-slate-200",
                            else: "text-slate-500 hover:text-slate-800"
                          )
                      ]}
                    >
                      Documents ({length(submitted_documents(@selected_landlord))})
                    </button>
                    <button
                      id="landlord-posted-houses-tab"
                      type="button"
                      role="tab"
                      aria-selected={@active_right_tab == "units"}
                      phx-click="select_right_tab"
                      phx-value-tab="units"
                      class={[
                        "px-4 py-3 text-sm font-medium transition",
                        @active_right_tab == "units" &&
                          if(@theme == "dark",
                            do: "border-b-2 border-indigo-500 font-semibold text-indigo-400",
                            else: "border-b-2 border-indigo-600 font-semibold text-indigo-700"
                          ),
                        @active_right_tab != "units" &&
                          if(@theme == "dark",
                            do: "text-slate-400 hover:text-slate-200",
                            else: "text-slate-500 hover:text-slate-800"
                          )
                      ]}
                    >
                      Posted houses
                    </button>
                  </div>

                  <%= if @active_right_tab == "details" do %>
                    <section class={[
                      "rounded-2xl border p-6 shadow-sm transition-colors",
                      @theme == "dark" && "border-slate-800 bg-slate-800/50",
                      @theme != "dark" && "border-slate-200 bg-white"
                    ]}>
                      <div class="flex flex-col items-start gap-5 sm:flex-row sm:items-center">
                        <div class={[
                          "flex size-20 shrink-0 items-center justify-center rounded-full text-2xl font-bold ring-4",
                          @theme == "dark" && "bg-indigo-950 text-indigo-300 ring-emerald-500/30",
                          @theme != "dark" && "bg-indigo-100 text-indigo-700 ring-emerald-500/20"
                        ]}>
                          {initials(@selected_landlord.names)}
                        </div>
                        <div class="flex-1 space-y-2">
                          <div class="flex flex-wrap items-center gap-3">
                            <h2 class={[
                              "text-2xl font-bold",
                              @theme == "dark" && "text-white",
                              @theme != "dark" && "text-slate-900"
                            ]}>
                              {@selected_landlord.names}
                            </h2>
                            <span class={[
                              "rounded-full px-3 py-1 text-xs font-semibold ring-1",
                              @theme == "dark" &&
                                "bg-emerald-950/50 text-emerald-400 ring-emerald-500/30",
                              @theme != "dark" && "bg-emerald-50 text-emerald-700 ring-emerald-600/20"
                            ]}>
                              <.icon name="hero-check-circle" class="mr-1 inline size-4" /> Verified
                            </span>
                          </div>
                          <p class={[
                            "text-sm capitalize",
                            @theme == "dark" && "text-slate-400",
                            @theme != "dark" && "text-slate-600"
                          ]}>
                            {@selected_landlord.entity_type || "Individual"} account
                          </p>
                        </div>
                      </div>
                    </section>

                    <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                      <section class={[
                        "rounded-2xl border p-5 shadow-sm transition-colors",
                        @theme == "dark" && "border-slate-800 bg-slate-800/50",
                        @theme != "dark" && "border-slate-200 bg-white"
                      ]}>
                        <h3 class={[
                          "mb-4 text-sm font-semibold",
                          @theme == "dark" && "text-white",
                          @theme != "dark" && "text-slate-900"
                        ]}>
                          Contact information
                        </h3>
                        <dl class="space-y-3 text-sm">
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              Email
                            </dt>
                            <dd class={[
                              "break-all font-medium",
                              @theme == "dark" && "text-slate-200",
                              @theme != "dark" && "text-slate-800"
                            ]}>
                              {@selected_landlord.email || "Not provided"}
                            </dd>
                          </div>
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              Phone
                            </dt>
                            <dd class={[
                              "font-medium",
                              @theme == "dark" && "text-slate-200",
                              @theme != "dark" && "text-slate-800"
                            ]}>
                              {@selected_landlord.phone || "Not provided"}
                            </dd>
                          </div>
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              WhatsApp
                            </dt>
                            <dd class={[
                              "font-medium",
                              @theme == "dark" && "text-slate-200",
                              @theme != "dark" && "text-slate-800"
                            ]}>
                              {@selected_landlord.whatsapp_phone || "Not provided"}
                            </dd>
                          </div>
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              Residence
                            </dt>
                            <dd class={[
                              "font-medium",
                              @theme == "dark" && "text-slate-200",
                              @theme != "dark" && "text-slate-800"
                            ]}>
                              {@selected_landlord.residence_location || "Not provided"}
                            </dd>
                          </div>
                        </dl>
                      </section>

                      <section class={[
                        "rounded-2xl border p-5 shadow-sm transition-colors",
                        @theme == "dark" && "border-slate-800 bg-slate-800/50",
                        @theme != "dark" && "border-slate-200 bg-white"
                      ]}>
                        <h3 class={[
                          "mb-4 text-sm font-semibold",
                          @theme == "dark" && "text-white",
                          @theme != "dark" && "text-slate-900"
                        ]}>
                          Verification and property
                        </h3>
                        <dl class="space-y-3 text-sm">
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              Verification status
                            </dt>
                            <dd class={[
                              "font-semibold capitalize",
                              @theme == "dark" && "text-emerald-400",
                              @theme != "dark" && "text-emerald-700"
                            ]}>
                              {@selected_landlord.verification_status}
                            </dd>
                          </div>
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              Property name
                            </dt>
                            <dd class={[
                              "font-medium",
                              @theme == "dark" && "text-slate-200",
                              @theme != "dark" && "text-slate-800"
                            ]}>
                              {@selected_landlord.property_name || "Not provided"}
                            </dd>
                          </div>
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              Property location
                            </dt>
                            <dd class={[
                              "font-medium",
                              @theme == "dark" && "text-slate-200",
                              @theme != "dark" && "text-slate-800"
                            ]}>
                              {@selected_landlord.property_location || "Not provided"}
                            </dd>
                          </div>
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              Listing purpose
                            </dt>
                            <dd class={[
                              "font-medium capitalize",
                              @theme == "dark" && "text-slate-200",
                              @theme != "dark" && "text-slate-800"
                            ]}>
                              {@selected_landlord.listing_purpose || "Not provided"}
                            </dd>
                          </div>
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              Units declared
                            </dt>
                            <dd class={[
                              "font-medium",
                              @theme == "dark" && "text-slate-200",
                              @theme != "dark" && "text-slate-800"
                            ]}>
                              {@selected_landlord.total_units || "Not provided"}
                            </dd>
                          </div>
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              Ownership type
                            </dt>
                            <dd class={[
                              "font-medium",
                              @theme == "dark" && "text-slate-200",
                              @theme != "dark" && "text-slate-800"
                            ]}>
                              {@selected_landlord.ownership_type || "Not provided"}
                            </dd>
                          </div>
                          <div>
                            <dt class={[
                              "text-xs",
                              @theme == "dark" && "text-slate-400",
                              @theme != "dark" && "text-slate-500"
                            ]}>
                              Title / LR number
                            </dt>
                            <dd class={[
                              "font-medium",
                              @theme == "dark" && "text-slate-200",
                              @theme != "dark" && "text-slate-800"
                            ]}>
                              {@selected_landlord.lr_number || "Not provided"}
                            </dd>
                          </div>
                        </dl>
                      </section>
                    </div>

                    <section class={[
                      "rounded-2xl border p-5 shadow-sm transition-colors",
                      @theme == "dark" && "border-slate-800 bg-slate-800/50",
                      @theme != "dark" && "border-slate-200 bg-white"
                    ]}>
                      <h3 class={[
                        "mb-4 text-sm font-semibold",
                        @theme == "dark" && "text-white",
                        @theme != "dark" && "text-slate-900"
                      ]}>
                        Identity and tax details
                      </h3>
                      <dl class="grid grid-cols-1 gap-4 text-sm sm:grid-cols-3">
                        <div>
                          <dt class={[
                            "text-xs",
                            @theme == "dark" && "text-slate-400",
                            @theme != "dark" && "text-slate-500"
                          ]}>
                            Identity document type
                          </dt>
                          <dd class={[
                            "font-medium",
                            @theme == "dark" && "text-slate-200",
                            @theme != "dark" && "text-slate-800"
                          ]}>
                            {@selected_landlord.id_type || "Not provided"}
                          </dd>
                        </div>
                        <div>
                          <dt class={[
                            "text-xs",
                            @theme == "dark" && "text-slate-400",
                            @theme != "dark" && "text-slate-500"
                          ]}>
                            Identity document number
                          </dt>
                          <dd class={[
                            "font-medium",
                            @theme == "dark" && "text-slate-200",
                            @theme != "dark" && "text-slate-800"
                          ]}>
                            {@selected_landlord.id_number || "Not provided"}
                          </dd>
                        </div>
                        <div>
                          <dt class={[
                            "text-xs",
                            @theme == "dark" && "text-slate-400",
                            @theme != "dark" && "text-slate-500"
                          ]}>
                            KRA PIN
                          </dt>
                          <dd class={[
                            "font-medium",
                            @theme == "dark" && "text-slate-200",
                            @theme != "dark" && "text-slate-800"
                          ]}>
                            {@selected_landlord.kra_pin || "Not provided"}
                          </dd>
                        </div>
                      </dl>
                    </section>

                    <section class={[
                      "rounded-2xl border p-5 shadow-sm transition-colors",
                      @theme == "dark" && "border-slate-800 bg-slate-800/50",
                      @theme != "dark" && "border-slate-200 bg-white"
                    ]}>
                      <h3 class={[
                        "mb-4 text-sm font-semibold",
                        @theme == "dark" && "text-white",
                        @theme != "dark" && "text-slate-900"
                      ]}>
                        Other registration answers
                      </h3>
                      <dl class="grid grid-cols-1 gap-4 text-sm sm:grid-cols-2 lg:grid-cols-3">
                        <div :for={entry <- registration_entries(@selected_landlord)}>
                          <dt class={[
                            "text-xs capitalize",
                            @dark_mode && "text-slate-400",
                            !@dark_mode && "text-slate-500"
                          ]}>
                            {entry.label}
                          </dt>
                          <dd class={[
                            "break-words font-medium",
                            @dark_mode && "text-slate-200",
                            !@dark_mode && "text-slate-800"
                          ]}>
                            {entry.value}
                          </dd>
                        </div>
                        <p
                          :if={registration_entries(@selected_landlord) == []}
                          class={[
                            "text-sm",
                            @theme == "dark" && "text-slate-400",
                            @theme != "dark" && "text-slate-500"
                          ]}
                        >
                          Additional registration answers were not saved for this account.
                        </p>
                      </dl>
                    </section>
                  <% else %>
                    <%= if @active_right_tab == "documents" do %>
                      <section class={[
                        "space-y-4 rounded-2xl border p-5 shadow-sm transition-colors",
                        @theme == "dark" && "border-slate-800 bg-slate-800/50",
                        @theme != "dark" && "border-slate-200 bg-white"
                      ]}>
                        <div>
                          <h2 class={[
                            "text-lg font-semibold",
                            @theme == "dark" && "text-white",
                            @theme != "dark" && "text-slate-900"
                          ]}>
                            Verification documents
                          </h2>
                          <p class={[
                            "mt-1 text-sm",
                            @dark_mode && "text-slate-400",
                            !@dark_mode && "text-slate-500"
                          ]}>
                            Uploaded files submitted with {@selected_landlord.names}'s registration.
                          </p>
                        </div>

                        <div
                          :if={submitted_documents(@selected_landlord) == []}
                          class={[
                            "rounded-xl border border-dashed px-4 py-10 text-center text-sm",
                            @dark_mode && "border-slate-700 text-slate-400",
                            !@dark_mode && "border-slate-300 text-slate-500"
                          ]}
                        >
                          No verification files were uploaded for this account.
                        </div>

                        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                          <article
                            :for={document <- submitted_documents(@selected_landlord)}
                            class={[
                              "overflow-hidden rounded-xl border transition-colors",
                              @dark_mode && "border-slate-700 bg-slate-800",
                              !@dark_mode && "border-slate-200 bg-slate-50"
                            ]}
                          >
                            <a
                              href={document.url}
                              target="_blank"
                              rel="noopener noreferrer"
                              class="block"
                            >
                              <img
                                :if={image_document?(document)}
                                src={document.url}
                                alt={document.label}
                                class={[
                                  "h-64 w-full object-contain",
                                  @dark_mode && "bg-slate-900",
                                  !@dark_mode && "bg-white"
                                ]}
                                loading="lazy"
                              />
                              <div
                                :if={!image_document?(document)}
                                class={[
                                  "flex h-48 flex-col items-center justify-center gap-3",
                                  @dark_mode && "bg-slate-900 text-indigo-400",
                                  !@dark_mode && "bg-white text-indigo-600"
                                ]}
                              >
                                <.icon name="hero-document-text" class="size-12" />
                                <span class="text-sm font-semibold">Open submitted file</span>
                              </div>
                            </a>
                            <div class={[
                              "flex items-start justify-between gap-3 border-t p-4",
                              @dark_mode && "border-slate-700",
                              !@dark_mode && "border-slate-200"
                            ]}>
                              <div class="min-w-0">
                                <h3 class={[
                                  "text-sm font-semibold",
                                  @dark_mode && "text-white",
                                  !@dark_mode && "text-slate-900"
                                ]}>
                                  {document.label}
                                </h3>
                                <p class={[
                                  "mt-1 truncate text-xs",
                                  @dark_mode && "text-slate-400",
                                  !@dark_mode && "text-slate-500"
                                ]}>
                                  {document.filename}
                                </p>
                                <p
                                  :if={document.content_type}
                                  class={[
                                    "mt-1 text-[10px]",
                                    @dark_mode && "text-slate-500",
                                    !@dark_mode && "text-slate-400"
                                  ]}
                                >
                                  {document.content_type}
                                </p>
                              </div>
                              <a
                                href={document.url}
                                target="_blank"
                                rel="noopener noreferrer"
                                class={[
                                  "shrink-0 rounded-lg border px-3 py-2 text-xs font-semibold transition",
                                  @dark_mode &&
                                    "border-slate-700 bg-slate-800 text-indigo-400 hover:bg-slate-700",
                                  !@dark_mode &&
                                    "border-slate-200 bg-white text-indigo-700 hover:bg-indigo-50"
                                ]}
                              >
                                Open
                              </a>
                            </div>
                          </article>
                        </div>
                      </section>
                    <% else %>
                      <div class={[
                        "rounded-xl border px-4 py-3 text-xs",
                        @dark_mode && "border-amber-900/50 bg-amber-950/30 text-amber-300",
                        !@dark_mode && "border-amber-200 bg-amber-50 text-amber-800"
                      ]}>
                        Sample posted houses for preview. Live listings will be connected later.
                      </div>
                      <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                        <article
                          :for={listing <- @mock_listings}
                          class={[
                            "overflow-hidden rounded-2xl border shadow-sm transition-colors",
                            @dark_mode && "border-slate-700 bg-slate-800",
                            !@dark_mode && "border-slate-200 bg-white"
                          ]}
                        >
                          <div class={[
                            "flex h-36 items-center justify-center bg-gradient-to-br",
                            @dark_mode && "from-indigo-950 to-slate-800",
                            !@dark_mode && "from-indigo-100 to-slate-200"
                          ]}>
                            <.icon
                              name="hero-home-modern"
                              class={[
                                "size-12",
                                @dark_mode && "text-indigo-500",
                                !@dark_mode && "text-indigo-400"
                              ]}
                            />
                          </div>
                          <div class="space-y-2 p-5">
                            <div class="flex items-start justify-between gap-3">
                              <h3 class={[
                                "font-semibold",
                                @dark_mode && "text-white",
                                !@dark_mode && "text-slate-900"
                              ]}>
                                {listing.title}
                              </h3>
                              <span class={[
                                "shrink-0 rounded-full px-2 py-1 text-[10px] font-semibold",
                                @dark_mode && "bg-emerald-950/50 text-emerald-400",
                                !@dark_mode && "bg-emerald-50 text-emerald-700"
                              ]}>
                                {listing.status}
                              </span>
                            </div>
                            <p class={[
                              "text-sm",
                              @dark_mode && "text-slate-400",
                              !@dark_mode && "text-slate-500"
                            ]}>
                              {listing.location}
                            </p>
                            <p class={[
                              "text-sm font-bold",
                              @dark_mode && "text-indigo-400",
                              !@dark_mode && "text-indigo-700"
                            ]}>
                              {listing.price}
                            </p>
                            <p class={[
                              "border-t pt-2 text-xs",
                              @dark_mode && "border-slate-700 text-slate-400",
                              !@dark_mode && "border-slate-100 text-slate-500"
                            ]}>
                              Posted by {@selected_landlord.names}
                            </p>
                          </div>
                        </article>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              <% else %>
                <div class={[
                  "flex h-full min-h-80 items-center justify-center text-center",
                  @dark_mode && "text-slate-400",
                  !@dark_mode && "text-slate-500"
                ]}>
                  No landlords have completed verification yet.
                </div>
              <% end %>
            </main>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp landlord_option(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="select_landlord"
      phx-value-id={@landlord.id}
      class={[
        "flex w-full items-center gap-3 rounded-xl border p-3 text-left transition",
        @selected &&
          if(@dark_mode,
            do: "border-indigo-800 bg-indigo-950/50 shadow-sm",
            else: "border-indigo-200 bg-indigo-50/70 shadow-sm"
          ),
        !@selected &&
          if(@dark_mode,
            do: "border-transparent bg-slate-900 hover:border-slate-800 hover:bg-slate-800",
            else: "border-transparent bg-white hover:border-slate-200 hover:bg-slate-50"
          )
      ]}
    >
      <div class={[
        "flex size-11 shrink-0 items-center justify-center rounded-full text-sm font-bold",
        @dark_mode && "bg-indigo-950 text-indigo-300",
        !@dark_mode && "bg-indigo-100 text-indigo-700"
      ]}>
        {initials(@landlord.names)}
      </div>
      <div class="min-w-0 flex-1">
        <div class="flex items-center justify-between gap-2">
          <h3 class={[
            "truncate text-sm font-semibold",
            @dark_mode && "text-white",
            !@dark_mode && "text-slate-900"
          ]}>
            {@landlord.names}
          </h3>
          <span class={[
            "shrink-0 text-[10px] font-semibold",
            @dark_mode && "text-emerald-400",
            !@dark_mode && "text-emerald-700"
          ]}>
            Verified
          </span>
        </div>
        <p class={[
          "mt-0.5 truncate text-xs",
          @dark_mode && "text-slate-400",
          !@dark_mode && "text-slate-500"
        ]}>
          {@landlord.property_name || @landlord.property_location || @landlord.email}
        </p>
      </div>
    </button>
    """
  end
end
