defmodule HomeWeb.Verify.Text do
  use HomeWeb, :live_view

  alias Home.Accounts

  @impl true
  def mount(_params, _session, socket) do
    # Fetch landlords pending verification with preloaded documents
    landlords = Accounts.list_pending_landlords_with_documents()
    selected_landlord = List.first(landlords)

    if connected?(socket) do
      Accounts.subscribe_verification_requests()
    end

    mock_chat_messages = [
      %{
        sender: "admin",
        author: "Admin Verification Team",
        time: "10:15 AM",
        text:
          "Hello! We are reviewing your submitted documents. Please reach out here if you have any questions."
      }
    ]

    {:ok,
     socket
     |> assign(:page_title, "Admin - Landlord Verification Hub")
     |> assign(:landlords, landlords)
     |> assign(:search_query, "")
     |> assign(:selected_landlord, selected_landlord)
     |> assign(:sidebar_open, false)
     |> assign(:active_tab, "1")
     |> assign(:show_chat, false)
     |> assign(:chat_messages, mock_chat_messages)
     |> assign(:message_text, "")
     |> assign(:approved_sections, %{})
     |> assign(:theme, "light")}
  end

  # pubsub helper functions
  @impl true
  def handle_info({:new_landlord_registration, landlord}, socket) do
    # Fetch preloaded documents for the new landlord if not preloaded in broadcast
    landlord_with_docs = Accounts.get_landlord_with_documents(landlord.id) || landlord

    # Prepend the new landlord to the list
    updated_landlords = [landlord_with_docs | socket.assigns.landlords]

    # If no landlord was selected initially, automatically select the new one
    selected_landlord = socket.assigns.selected_landlord || landlord_with_docs

    {:noreply,
     socket
     |> put_flash(:info, "New landlord registration completed: #{landlord.names}")
     |> assign(:landlords, updated_landlords)
     |> assign(:selected_landlord, selected_landlord)}
  end

  @impl true
  def handle_info({:new_verification_request, _request}, socket) do
    # Refresh the list when a general verification request is created
    landlords = Accounts.list_pending_landlords_with_documents()

    {:noreply,
     socket
     |> put_flash(:info, "New verification request received")
     |> assign(:landlords, landlords)}
  end

  @impl true
  def handle_event("search_landlords", %{"search" => query}, socket) do
    filtered =
      socket.assigns.landlords
      |> Enum.filter(fn l ->
        name = String.downcase(l.names || "")
        email = String.downcase(l.email || "")
        q = String.downcase(query)
        String.contains?(name, q) or String.contains?(email, q)
      end)

    selected =
      if Enum.member?(filtered, socket.assigns.selected_landlord),
        do: socket.assigns.selected_landlord,
        else: List.first(filtered)

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:selected_landlord, selected)}
  end

  def handle_event("select_landlord", %{"id" => landlord_id}, socket) do
    landlord = Enum.find(socket.assigns.landlords, &(to_string(&1.id) == landlord_id))

    {:noreply,
     socket
     |> assign(:selected_landlord, landlord)
     |> assign(:sidebar_open, false)}
  end

  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("toggle_theme", _, socket) do
    new_theme = if socket.assigns.theme == "dark", do: "light", else: "dark"

    {:noreply,
     socket
     |> assign(:theme, new_theme)
     |> push_event("set_global_theme", %{theme: new_theme})}
  end

  def handle_event("restore_theme", %{"theme" => theme}, socket)
      when theme in ["dark", "light"] do
    {:noreply, assign(socket, :theme, theme)}
  end

  @impl true
  def handle_event("approve_section", %{"section" => section}, socket) do
    landlord = socket.assigns.selected_landlord

    case Accounts.update_landlord_section_status(landlord, section, "approved") do
      {:ok, updated_landlord} ->
        {:noreply,
         socket
         |> update_landlord_in_assigns(updated_landlord)
         |> put_flash(:info, "Approved #{section} for #{updated_landlord.names || "Landlord"}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update status.")}
    end
  end

  @impl true
  def handle_event("reject_section", %{"section" => section}, socket) do
    landlord = socket.assigns.selected_landlord

    case Accounts.update_landlord_section_status(landlord, section, "rejected") do
      {:ok, updated_landlord} ->
        {:noreply,
         socket
         |> update_landlord_in_assigns(updated_landlord)
         |> put_flash(:error, "Rejected #{section} for #{updated_landlord.names || "Landlord"}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update status.")}
    end
  end

  @impl true
  def handle_event("open_inquire_modal", %{"section" => section}, socket) do
    default_msg = "Hello, we have a question regarding your #{section}. Please clarify."

    {:noreply,
     socket
     |> assign(:active_inquire_section, section)
     |> assign(:message_text, default_msg)
     |> assign(:show_chat, true)}
  end

  def handle_event("toggle_chat", _params, socket) do
    {:noreply, update(socket, :show_chat, &(!&1))}
  end

  def handle_event("update_message", %{"message" => msg}, socket) do
    {:noreply, assign(socket, :message_text, msg)}
  end

  @impl true
  def handle_event("send_message", %{"message" => msg}, socket) when byte_size(msg) > 0 do
    landlord = socket.assigns.selected_landlord
    section = socket.assigns[:active_inquire_section] || "Personal Details"

    case Accounts.update_landlord_section_status(landlord, section, "inquired", msg) do
      {:ok, updated_landlord} ->
        new_msg = %{
          sender: "admin",
          author: "Admin Verification Team",
          time: Calendar.strftime(Time.utc_now(), "%I:%M %p"),
          text: msg
        }

        {:noreply,
         socket
         |> update_landlord_in_assigns(updated_landlord)
         |> update(:chat_messages, fn msgs -> msgs ++ [new_msg] end)
         |> assign(:message_text, "")
         |> put_flash(:info, "Inquiry sent for #{section}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to send inquiry.")}
    end
  end

  @impl true
  def handle_event("approve_final_verification", %{"id" => _id}, socket) do
    landlord = socket.assigns.selected_landlord

    case Accounts.update_landlord_status(landlord, "approved") do
      {:ok, _updated_landlord} ->
        remaining_landlords = Enum.reject(socket.assigns.landlords, &(&1.id == landlord.id))
        next_selected = List.first(remaining_landlords)

        {:noreply,
         socket
         |> assign(:landlords, remaining_landlords)
         |> assign(:selected_landlord, next_selected)
         |> put_flash(
           :info,
           "#{landlord.names || "Landlord"} has been approved and granted access."
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not finalize verification.")}
    end
  end

  @impl true
  def handle_event("reject_final_verification", %{"id" => _id}, socket) do
    landlord = socket.assigns.selected_landlord

    case Accounts.update_landlord_status(landlord, "rejected") do
      {:ok, _updated_landlord} ->
        remaining_landlords = Enum.reject(socket.assigns.landlords, &(&1.id == landlord.id))
        next_selected = List.first(remaining_landlords)

        {:noreply,
         socket
         |> assign(:landlords, remaining_landlords)
         |> assign(:selected_landlord, next_selected)
         |> put_flash(:error, "#{landlord.names || "Landlord"} application rejected.")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not reject application.")}
    end
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  # Helper to keep socket lists in sync
  defp update_landlord_in_assigns(socket, updated_landlord) do
    updated_landlords =
      Enum.map(socket.assigns.landlords, fn l ->
        if l.id == updated_landlord.id, do: updated_landlord, else: l
      end)

    socket
    |> assign(:landlords, updated_landlords)
    |> assign(:selected_landlord, updated_landlord)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section
        id="admin-landlord-verification"
        phx-hook="HouseFinder"
        class={[
          "fixed inset-0 z-40 flex overflow-hidden transition-colors duration-200",
          @theme == "dark" && "bg-[#0b1220] text-slate-100",
          @theme == "light" && "bg-[#f8fafc] text-slate-900"
        ]}
      >
        <%!-- Mobile Sidebar Overlay Backdrop --%>
        <div
          :if={@sidebar_open}
          class="fixed inset-0 z-40 bg-slate-900/60 backdrop-blur-sm lg:hidden"
          phx-click="toggle_sidebar"
        >
        </div>

        <%!-- Collapsible Sidebar (Left) --%>
        <aside class={[
          "fixed inset-y-0 left-0 z-50 flex w-80 flex-col border-r transition-transform duration-300 lg:static lg:translate-x-0",
          !@sidebar_open && "-translate-x-full lg:translate-x-0",
          @theme == "dark" && "border-slate-800 bg-[#0e1626]",
          @theme == "light" && "border-slate-200 bg-white"
        ]}>
          <%!-- Sidebar Header & Search Bar --%>
          <div class={[
            "flex flex-col gap-3 border-b p-4",
            @theme == "dark" && "border-slate-800 bg-[#131d31]",
            @theme == "light" && "border-slate-200 bg-slate-50"
          ]}>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <div class="flex size-8 items-center justify-center rounded-lg bg-blue-600/10 text-blue-600">
                  <.icon name="hero-user-group" class="size-5" />
                </div>
                <div>
                  <h2 class={[
                    "text-sm font-bold tracking-tight",
                    @theme == "dark" && "text-white",
                    @theme == "light" && "text-slate-900"
                  ]}>
                    Landlords Pending
                  </h2>
                  <p class="text-[10px] text-slate-500">
                    {length(filtered_landlords(@landlords, @search_query))} Applications
                  </p>
                </div>
              </div>
              <button
                type="button"
                class="rounded-lg p-1.5 text-slate-500 hover:bg-slate-200 lg:hidden"
                phx-click="toggle_sidebar"
              >
                <.icon name="hero-x-mark" class="size-5" />
              </button>
            </div>

            <%!-- Search Input --%>
            <form phx-change="search_landlords" phx-submit="search_landlords" class="relative">
              <input
                type="text"
                name="search"
                value={@search_query}
                placeholder="Search landlord name, email..."
                class={[
                  "w-full rounded-xl border py-2 pl-9 pr-3 text-xs focus:border-blue-600 focus:outline-none",
                  @theme == "dark" &&
                    "border-slate-700 bg-[#090d16] text-white placeholder-slate-500",
                  @theme == "light" &&
                    "border-slate-300 bg-white text-slate-900 placeholder-slate-400"
                ]}
              />
              <.icon
                name="hero-magnifying-glass"
                class="absolute left-3 top-2.5 size-4 text-slate-400"
              />
            </form>
          </div>

          <%!-- Landlords Scrollable List --%>
          <div class="flex-1 space-y-1.5 overflow-y-auto p-3">
            <%= if Enum.empty?(filtered_landlords(@landlords, @search_query)) do %>
              <div class="p-4 text-center text-xs text-slate-400">
                No landlords matching request.
              </div>
            <% else %>
              <button
                :for={landlord <- filtered_landlords(@landlords, @search_query)}
                type="button"
                phx-click="select_landlord"
                phx-value-id={landlord.id}
                class={[
                  "flex w-full flex-col gap-1 rounded-xl border p-3 text-left transition",
                  @selected_landlord && @selected_landlord.id == landlord.id &&
                    "border-blue-600 bg-blue-600/10 shadow-sm",
                  (@selected_landlord == nil or @selected_landlord.id != landlord.id) &&
                    @theme == "dark" && "border-slate-800 bg-[#090d16] hover:bg-slate-800/50",
                  (@selected_landlord == nil or @selected_landlord.id != landlord.id) &&
                    @theme == "light" && "border-slate-200 bg-slate-50 hover:bg-slate-100"
                ]}
              >
                <div class="flex items-center justify-between">
                  <span class={[
                    "font-bold text-xs truncate",
                    @theme == "dark" && "text-slate-100",
                    @theme == "light" && "text-slate-800"
                  ]}>
                    {landlord.names || "Unnamed Landlord"}
                  </span>
                  <span class="rounded bg-amber-500/10 px-1.5 py-0.5 text-[10px] font-semibold text-amber-500">
                    Pending
                  </span>
                </div>
                <p class="text-[11px] text-slate-400 truncate">
                  {landlord.email || "No email provided"}
                </p>
                <div class="mt-1 flex items-center justify-between text-[10px] text-slate-500">
                  <span>{landlord.property_name || "Property Pending"}</span>
                  <span>{length(landlord.documents || [])} Docs</span>
                </div>
              </button>
            <% end %>
          </div>
        </aside>

        <%!-- Main Verification Panel (Right Container) --%>
        <div class="flex flex-1 flex-col overflow-y-auto">
          <div class="mx-auto flex w-full max-w-5xl flex-col px-4 py-6 sm:px-6 lg:px-8">
            <%!-- Top Action Bar --%>
            <div class="flex items-center justify-between pb-4">
              <button
                type="button"
                phx-click="toggle_sidebar"
                class={[
                  "flex items-center gap-2 rounded-xl border px-3 py-2 text-xs font-semibold lg:hidden",
                  @theme == "dark" && "border-slate-800 bg-[#0e1626] text-slate-200",
                  @theme == "light" && "border-slate-200 bg-white text-slate-700 shadow-sm"
                ]}
              >
                <.icon name="hero-bars-3" class="size-4" />
                <span>Select Landlord</span>
              </button>

              <div class="ml-auto flex items-center gap-3">
                <button
                  type="button"
                  phx-click="toggle_theme"
                  class={[
                    "flex size-10 items-center justify-center rounded-full border transition active:scale-95",
                    @theme == "dark" &&
                      "border-slate-700 bg-[#0e1626] text-amber-400 hover:bg-slate-800",
                    @theme == "light" &&
                      "border-slate-300 bg-white text-slate-700 shadow-sm hover:bg-slate-100"
                  ]}
                  title={"Switch to #{if @theme == "dark", do: "Light", else: "Dark"} mode"}
                >
                  <%= if @theme == "dark" do %>
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
                        d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z"
                      />
                    </svg>
                  <% else %>
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
                        d="M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75c0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z"
                      />
                    </svg>
                  <% end %>
                </button>
              </div>
            </div>

            <%= if @selected_landlord == nil do %>
              <div class="flex flex-1 flex-col items-center justify-center rounded-2xl border p-12 text-center">
                <.icon name="hero-user-circle" class="size-16 text-slate-400" />
                <h3 class="mt-4 text-base font-bold">No Landlord Selected</h3>
                <p class="text-xs text-slate-500">
                  Select an applicant from the sidebar to start reviewing their details.
                </p>
              </div>
            <% else %>
              <% steps = build_verification_steps(@selected_landlord, @approved_sections) %>
              <% completed_steps_count = Enum.count(steps, & &1.completed?) %>
              <% total_steps_count = length(steps) %>
              <% progress_percentage =
                if total_steps_count > 0,
                  do: round(completed_steps_count / total_steps_count * 100),
                  else: 0 %>

              <%!-- Top Centered Branding & Header Content --%>
              <header class={[
                "relative flex flex-col items-center justify-center border-b pb-6 text-center",
                @theme == "dark" && "border-slate-800",
                @theme == "light" && "border-slate-200"
              ]}>
                <div class="mb-4 flex items-center justify-end gap-3 sm:absolute sm:right-0 sm:top-0 sm:mb-0">
                  <div class="text-right">
                    <p class={[
                      "text-[10px] font-semibold uppercase tracking-wider",
                      @theme == "dark" && "text-slate-400",
                      @theme == "light" && "text-slate-500"
                    ]}>
                      Progress
                    </p>
                    <p class="text-lg font-bold text-emerald-500">{progress_percentage}%</p>
                  </div>
                </div>

                <h1 class={[
                  "text-3xl font-extrabold tracking-tight sm:text-4xl md:text-5xl",
                  @theme == "dark" && "text-white",
                  @theme == "light" && "text-slate-900"
                ]}>
                  Home Admin
                </h1>

                <%!-- Dynamic Greeting & Subtitle --%>
                <div class="mt-2 space-y-1">
                  <h2 class={[
                    "text-lg font-bold sm:text-xl md:text-2xl",
                    @theme == "dark" && "text-slate-100",
                    @theme == "light" && "text-slate-800"
                  ]}>
                    Reviewing: {first_name(@selected_landlord) || "Landlord"} ({detail(
                      @selected_landlord,
                      :names
                    )})
                  </h2>
                  <p class={[
                    "text-xs sm:text-sm",
                    @theme == "dark" && "text-slate-400",
                    @theme == "light" && "text-slate-600"
                  ]}>
                    Submitted documents ready for audit.<br />
                    ⚠️Verify all official documents before approving access.
                  </p>
                </div>

                <%!-- Progress Badge Banner --%>
                <div class={[
                  "mt-6 flex w-full max-w-md items-center justify-between gap-4 rounded-2xl border p-4 shadow-sm",
                  @theme == "dark" && "border-slate-800 bg-[#0e1626]",
                  @theme == "light" && "border-slate-200 bg-white"
                ]}>
                  <div class="flex size-12 shrink-0 items-center justify-center rounded-xl bg-emerald-500/20 text-emerald-500">
                    <.icon name="hero-shield-check" class="size-7" />
                  </div>
                  <div class="flex-1 text-left">
                    <div class="flex items-center justify-between gap-3">
                      <p class="text-xs font-semibold uppercase tracking-wider text-emerald-500">
                        Overall Progress
                      </p>
                      <span class="text-sm font-bold text-emerald-500">{progress_percentage}%</span>
                    </div>
                    <p class={[
                      "mt-0.5 text-xs font-medium sm:text-sm",
                      @theme == "dark" && "text-slate-300",
                      @theme == "light" && "text-slate-700"
                    ]}>
                      {completed_steps_count} of {total_steps_count} Steps Verified
                    </p>
                    <div class={[
                      "mt-2 h-2 w-full overflow-hidden rounded-full",
                      @theme == "dark" && "bg-slate-800",
                      @theme == "light" && "bg-slate-100"
                    ]}>
                      <div
                        class="h-full rounded-full bg-blue-600 transition-all duration-500"
                        style={"width: #{progress_percentage}%"}
                      >
                      </div>
                    </div>
                  </div>
                </div>
              </header>

              <%!-- Verification Step Tabs --%>
              <div class="mt-8">
                <div class="flex items-center justify-between pb-2">
                  <h3 class={[
                    "text-xs font-semibold uppercase tracking-wider",
                    @theme == "dark" && "text-slate-400",
                    @theme == "light" && "text-slate-500"
                  ]}>
                    Verification Steps
                  </h3>
                  <span class={[
                    "text-xs",
                    @theme == "dark" && "text-slate-500",
                    @theme == "light" && "text-slate-400"
                  ]}>
                    Select step to view details
                  </span>
                </div>

                <div class="no-scrollbar flex gap-2 overflow-x-auto pb-2">
                  <button
                    :for={step <- steps}
                    type="button"
                    phx-click="select_tab"
                    phx-value-tab={to_string(step.number)}
                    class={[
                      "flex shrink-0 items-center gap-2.5 rounded-xl border px-4 py-2.5 text-xs font-semibold transition",
                      @active_tab == to_string(step.number) &&
                        "border-blue-600 bg-blue-600 text-white shadow-md",
                      @active_tab != to_string(step.number) && step.completed? && @theme == "dark" &&
                        "border-emerald-500/40 bg-[#0e1626] text-emerald-400 hover:bg-slate-800",
                      @active_tab != to_string(step.number) && step.completed? && @theme == "light" &&
                        "border-emerald-500/40 bg-white text-emerald-600 hover:bg-slate-50",
                      @active_tab != to_string(step.number) && !step.completed? && @theme == "dark" &&
                        "border-slate-800 bg-[#0e1626] text-slate-400 hover:bg-slate-800",
                      @active_tab != to_string(step.number) && !step.completed? && @theme == "light" &&
                        "border-slate-200 bg-white text-slate-600 hover:bg-slate-50"
                    ]}
                  >
                    <span class={[
                      "flex size-5 items-center justify-center rounded-full text-[10px] font-bold",
                      step.completed? && "bg-emerald-500 text-white",
                      !step.completed? && @theme == "dark" && "bg-slate-800 text-slate-300",
                      !step.completed? && @theme == "light" && "bg-slate-200 text-slate-700"
                    ]}>
                      {if step.completed?, do: "✓", else: step.number}
                    </span>
                    <span>{step.number}. {step.title}</span>
                  </button>
                </div>
              </div>

              <%!-- Step-by-Step Sections --%>
              <main class="mt-6 flex-1 space-y-6 pb-28">
                <%!-- Step 1: Personal Details --%>
                <div
                  :if={@active_tab == "1"}
                  class={[
                    "rounded-2xl border p-5 transition-all sm:p-6",
                    @theme == "dark" && "border-slate-800 bg-[#0e1626] shadow-xl",
                    @theme == "light" && "border-slate-200 bg-white shadow-sm"
                  ]}
                >
                  <div class={[
                    "flex items-center justify-between border-b pb-3",
                    @theme == "dark" && "border-slate-800",
                    @theme == "light" && "border-slate-200"
                  ]}>
                    <div class="flex items-center gap-2.5">
                      <h3 class={[
                        "text-lg font-bold",
                        @theme == "dark" && "text-white",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        Personal details
                      </h3>
                      <span
                        :if={Enum.at(steps, 0).completed?}
                        class="flex items-center text-emerald-500"
                      >
                        <.icon name="hero-check-circle-solid" class="size-5" />
                      </span>
                    </div>
                  </div>

                  <div class="mt-4 grid grid-cols-1 gap-y-3.5 gap-x-8 text-sm sm:grid-cols-2">
                    <div class={[
                      "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                      @theme == "dark" && "sm:border-slate-800/60",
                      @theme == "light" && "sm:border-slate-100"
                    ]}>
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Category:
                      </span>
                      <span class={[
                        "font-medium capitalize",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :entity_type)}
                      </span>
                    </div>
                    <div class={[
                      "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                      @theme == "dark" && "sm:border-slate-800/60",
                      @theme == "light" && "sm:border-slate-100"
                    ]}>
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Name:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :names)}
                      </span>
                    </div>
                    <div class={[
                      "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                      @theme == "dark" && "sm:border-slate-800/60",
                      @theme == "light" && "sm:border-slate-100"
                    ]}>
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Email:
                      </span>
                      <span class={[
                        "break-all font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :email)}
                      </span>
                    </div>
                    <div class={[
                      "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                      @theme == "dark" && "sm:border-slate-800/60",
                      @theme == "light" && "sm:border-slate-100"
                    ]}>
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Phone:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :phone)}
                      </span>
                    </div>
                    <div class="flex flex-col sm:flex-row sm:justify-between">
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        WhatsApp:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :whatsapp_phone)}
                      </span>
                    </div>
                    <div class="flex flex-col sm:flex-row sm:justify-between">
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Residence:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :residence_location)}
                      </span>
                    </div>
                  </div>

                  <%!-- Section Review Action Controls --%>
                  <.section_action_bar section="Personal Details" theme={@theme} />
                </div>

                <%!-- Step 2: Identity Verification & Uploads --%>
                <div
                  :if={@active_tab == "2"}
                  class={[
                    "rounded-2xl border p-5 transition-all sm:p-6",
                    @theme == "dark" && "border-slate-800 bg-[#0e1626] shadow-xl",
                    @theme == "light" && "border-slate-200 bg-white shadow-sm"
                  ]}
                >
                  <div class={[
                    "flex items-center justify-between border-b pb-3",
                    @theme == "dark" && "border-slate-800",
                    @theme == "light" && "border-slate-200"
                  ]}>
                    <div class="flex items-center gap-2.5">
                      <h3 class={[
                        "text-lg font-bold",
                        @theme == "dark" && "text-white",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        Identity verification
                      </h3>
                      <span
                        :if={Enum.at(steps, 1).completed?}
                        class="flex items-center text-emerald-500"
                      >
                        <.icon name="hero-check-circle-solid" class="size-5" />
                      </span>
                    </div>
                  </div>

                  <div class="mt-4 grid grid-cols-1 gap-y-3.5 gap-x-8 text-sm sm:grid-cols-2">
                    <div class={[
                      "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                      @theme == "dark" && "sm:border-slate-800/60",
                      @theme == "light" && "sm:border-slate-100"
                    ]}>
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Doc type:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :id_type)}
                      </span>
                    </div>
                    <div class={[
                      "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                      @theme == "dark" && "sm:border-slate-800/60",
                      @theme == "light" && "sm:border-slate-100"
                    ]}>
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Doc / ID no:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :id_number)}
                      </span>
                    </div>
                    <div class="flex flex-col sm:flex-row sm:justify-between">
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        KRA PIN:
                      </span>
                      <span class={[
                        "font-medium uppercase",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :kra_pin)}
                      </span>
                    </div>
                    <div class="flex flex-col sm:flex-row sm:justify-between">
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Uploads status:
                      </span>
                      <span class="font-medium text-emerald-500">
                        {if has_doc?(@selected_landlord, "id_front") or
                              has_value?(@selected_landlord, :id_front_url),
                            do: "Front attached, ",
                            else: ""}
                        {if has_doc?(@selected_landlord, "id_back") or
                              has_value?(@selected_landlord, :id_back_url),
                            do: "Back attached",
                            else: "Pending uploads"}
                      </span>
                    </div>
                  </div>

                  <%!-- Identity Document Image Previews --%>
                  <div class={[
                    "mt-6 border-t pt-4",
                    @theme == "dark" && "border-slate-800",
                    @theme == "light" && "border-slate-200"
                  ]}>
                    <h4 class={[
                      "mb-3 text-xs font-semibold uppercase tracking-wider",
                      @theme == "dark" && "text-slate-400",
                      @theme == "light" && "text-slate-500"
                    ]}>
                      Uploaded Identity Pictures
                    </h4>
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                      <.doc_card
                        title="ID Front Picture"
                        url={get_doc_url(@selected_landlord, :id_front_url, "id_front")}
                        theme={@theme}
                      />
                      <.doc_card
                        title="ID Back Picture"
                        url={get_doc_url(@selected_landlord, :id_back_url, "id_back")}
                        theme={@theme}
                      />
                      <.doc_card
                        title="KRA PIN Certificate"
                        url={get_doc_url(@selected_landlord, :kra_doc_url, "kra_doc")}
                        theme={@theme}
                      />
                    </div>
                  </div>

                  <%!-- Section Review Action Controls --%>
                  <.section_action_bar section="Identity Verification" theme={@theme} />
                </div>

                <%!-- Step 3: Property Details & Uploads --%>
                <div
                  :if={@active_tab == "3"}
                  class={[
                    "rounded-2xl border p-5 transition-all sm:p-6",
                    @theme == "dark" && "border-slate-800 bg-[#0e1626] shadow-xl",
                    @theme == "light" && "border-slate-200 bg-white shadow-sm"
                  ]}
                >
                  <div class={[
                    "flex items-center justify-between border-b pb-3",
                    @theme == "dark" && "border-slate-800",
                    @theme == "light" && "border-slate-200"
                  ]}>
                    <div class="flex items-center gap-2.5">
                      <h3 class={[
                        "text-lg font-bold",
                        @theme == "dark" && "text-white",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        Property details
                      </h3>
                      <span
                        :if={Enum.at(steps, 2).completed?}
                        class="flex items-center text-emerald-500"
                      >
                        <.icon name="hero-check-circle-solid" class="size-5" />
                      </span>
                    </div>
                  </div>

                  <div class="mt-4 grid grid-cols-1 gap-y-3.5 gap-x-8 text-sm sm:grid-cols-2">
                    <div class={[
                      "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                      @theme == "dark" && "sm:border-slate-800/60",
                      @theme == "light" && "sm:border-slate-100"
                    ]}>
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Intent:
                      </span>
                      <span class={[
                        "font-medium capitalize",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :listing_purpose)}
                      </span>
                    </div>
                    <div class={[
                      "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                      @theme == "dark" && "sm:border-slate-800/60",
                      @theme == "light" && "sm:border-slate-100"
                    ]}>
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Property name:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :property_name)}
                      </span>
                    </div>
                    <div class={[
                      "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                      @theme == "dark" && "sm:border-slate-800/60",
                      @theme == "light" && "sm:border-slate-100"
                    ]}>
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Location:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :property_location)}
                      </span>
                    </div>
                    <div class={[
                      "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                      @theme == "dark" && "sm:border-slate-800/60",
                      @theme == "light" && "sm:border-slate-100"
                    ]}>
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Ownership type:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :ownership_type)}
                      </span>
                    </div>
                    <div class="flex flex-col sm:flex-row sm:justify-between">
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Title / LR no:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :lr_number)}
                      </span>
                    </div>
                    <div class="flex flex-col sm:flex-row sm:justify-between">
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Total units:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :total_units)}
                      </span>
                    </div>
                  </div>

                  <%!-- Property Ownership Document Picture --%>
                  <div class={[
                    "mt-6 border-t pt-4",
                    @theme == "dark" && "border-slate-800",
                    @theme == "light" && "border-slate-200"
                  ]}>
                    <h4 class={[
                      "mb-3 text-xs font-semibold uppercase tracking-wider",
                      @theme == "dark" && "text-slate-400",
                      @theme == "light" && "text-slate-500"
                    ]}>
                      Ownership Document Picture
                    </h4>
                    <div class="max-w-sm">
                      <.doc_card
                        title="Proof of Ownership / Title Deed"
                        url={get_doc_url(@selected_landlord, :ownership_doc_url, "ownership_doc")}
                        theme={@theme}
                      />
                    </div>
                  </div>

                  <%!-- Section Review Action Controls --%>
                  <.section_action_bar section="Property Details" theme={@theme} />
                </div>

                <%!-- Step 4: Billing & Payment --%>
                <div
                  :if={@active_tab == "4"}
                  class={[
                    "rounded-2xl border p-5 transition-all sm:p-6",
                    @theme == "dark" && "border-slate-800 bg-[#0e1626] shadow-xl",
                    @theme == "light" && "border-slate-200 bg-white shadow-sm"
                  ]}
                >
                  <div class={[
                    "flex items-center justify-between border-b pb-3",
                    @theme == "dark" && "border-slate-800",
                    @theme == "light" && "border-slate-200"
                  ]}>
                    <div class="flex items-center gap-2.5">
                      <h3 class={[
                        "text-lg font-bold",
                        @theme == "dark" && "text-white",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        Billing & payment
                      </h3>
                      <span
                        :if={Enum.at(steps, 3).completed?}
                        class="flex items-center text-emerald-500"
                      >
                        <.icon name="hero-check-circle-solid" class="size-5" />
                      </span>
                    </div>
                  </div>

                  <div class="mt-4 grid grid-cols-1 gap-y-3.5 gap-x-8 text-sm sm:grid-cols-2">
                    <div class="flex flex-col sm:flex-row sm:justify-between">
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Billing method:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :billing_method)}
                      </span>
                    </div>
                    <div class="flex flex-col sm:flex-row sm:justify-between">
                      <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>
                        Billing phone:
                      </span>
                      <span class={[
                        "font-medium",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :billing_phone)}
                      </span>
                    </div>
                  </div>

                  <%!-- Section Review Action Controls --%>
                  <.section_action_bar section="Billing & Payment" theme={@theme} />
                </div>

                <%!-- Step 5: Final Approval --%>
                <div
                  :if={@active_tab == "5"}
                  id="final-approval-step"
                  class={[
                    "rounded-2xl border p-5 transition-all sm:p-6",
                    @theme == "dark" && "border-slate-800 bg-[#0e1626] shadow-xl",
                    @theme == "light" && "border-slate-200 bg-white shadow-sm"
                  ]}
                >
                  <div class={[
                    "flex flex-col gap-4 border-b pb-4 sm:flex-row sm:items-start sm:justify-between",
                    @theme == "dark" && "border-slate-800",
                    @theme == "light" && "border-slate-200"
                  ]}>
                    <div>
                      <h3 class={[
                        "text-lg font-bold",
                        @theme == "dark" && "text-white",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        Final approval
                      </h3>
                      <p class={[
                        "mt-1 text-xs",
                        @theme == "dark" && "text-slate-400",
                        @theme == "light" && "text-slate-500"
                      ]}>
                        Confirm the landlord can access the owner dashboard and start sharing their property.
                      </p>
                    </div>

                    <span class={[
                      "inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold capitalize",
                      @selected_landlord.verification_status == "approved" &&
                        "bg-emerald-500/10 text-emerald-600",
                      @selected_landlord.verification_status == "rejected" &&
                        "bg-rose-500/10 text-rose-600",
                      @selected_landlord.verification_status in ["pending", "inquired"] &&
                        "bg-amber-500/10 text-amber-600"
                    ]}>
                      <.icon name="hero-shield-check" class="size-4" />
                      {@selected_landlord.verification_status || "pending"}
                    </span>
                  </div>

                  <div class="mt-5 grid gap-3 text-sm sm:grid-cols-2">
                    <div class={[
                      "rounded-xl border p-4",
                      @theme == "dark" && "border-slate-800 bg-[#090d16]",
                      @theme == "light" && "border-slate-200 bg-slate-50"
                    ]}>
                      <p class="text-xs font-semibold uppercase text-slate-500">Purpose</p>
                      <p class={[
                        "mt-1 font-semibold capitalize",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :listing_purpose)}
                      </p>
                    </div>

                    <div class={[
                      "rounded-xl border p-4",
                      @theme == "dark" && "border-slate-800 bg-[#090d16]",
                      @theme == "light" && "border-slate-200 bg-slate-50"
                    ]}>
                      <p class="text-xs font-semibold uppercase text-slate-500">Property</p>
                      <p class={[
                        "mt-1 font-semibold",
                        @theme == "dark" && "text-slate-100",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        {detail(@selected_landlord, :property_name)}
                      </p>
                    </div>
                  </div>

                  <div class={[
                    "mt-6 flex flex-wrap items-center justify-end gap-3 border-t pt-4",
                    @theme == "dark" && "border-slate-800",
                    @theme == "light" && "border-slate-200"
                  ]}>
                    <button
                      id="reject-final-verification"
                      type="button"
                      phx-click="reject_final_verification"
                      phx-value-id={@selected_landlord.id}
                      class="flex items-center gap-1.5 rounded-xl border border-rose-500/30 bg-rose-500/10 px-4 py-2 text-xs font-semibold text-rose-600 transition hover:bg-rose-500 hover:text-white"
                    >
                      <.icon name="hero-x-circle" class="size-4" />
                      <span>Reject Application</span>
                    </button>

                    <button
                      id="approve-final-verification"
                      type="button"
                      phx-click="approve_final_verification"
                      phx-value-id={@selected_landlord.id}
                      class="flex items-center gap-1.5 rounded-xl bg-emerald-600 px-4 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-emerald-700"
                    >
                      <.icon name="hero-check-circle" class="size-4" />
                      <span>Approve Landlord</span>
                    </button>
                  </div>
                </div>
              </main>
            <% end %>

            <%!-- Responsive Floating Chat Button --%>
            <div class="fixed bottom-4 right-4 z-40 sm:bottom-6 sm:right-6">
              <button
                type="button"
                phx-click="toggle_chat"
                class="flex items-center gap-2 rounded-full bg-blue-600 px-4 py-3 text-xs font-bold text-white shadow-lg transition hover:bg-blue-700 active:scale-95 sm:px-5 sm:py-3.5 sm:text-sm"
              >
                <.icon name="hero-chat-bubble-left-right" class="size-5 sm:size-6" />
                <span>Message Landlord</span>
                <span :if={length(@chat_messages) > 0} class="flex size-2 rounded-full bg-emerald-400">
                </span>
              </button>
            </div>

            <%!-- Direct Verification Support Chat Modal --%>
            <div
              :if={@show_chat}
              class="fixed inset-0 z-50 flex flex-col justify-end sm:items-end sm:p-6"
            >
              <div
                class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity"
                phx-click="toggle_chat"
              >
              </div>

              <div class={[
                "relative z-10 flex h-[85vh] max-h-[550px] w-full flex-col overflow-hidden rounded-t-2xl border shadow-2xl sm:h-[500px] sm:w-[420px] sm:rounded-2xl",
                @theme == "dark" && "border-slate-800 bg-[#0e1626]",
                @theme == "light" && "border-slate-200 bg-white"
              ]}>
                <%!-- Header --%>
                <div class={[
                  "flex items-center justify-between border-b px-4 py-3",
                  @theme == "dark" && "border-slate-800 bg-[#131d31]",
                  @theme == "light" && "border-slate-200 bg-slate-50"
                ]}>
                  <div class="flex items-center gap-3">
                    <div class="flex size-8 items-center justify-center rounded-full bg-blue-600/10 text-blue-600">
                      <.icon name="hero-chat-bubble-bottom-center-text" class="size-4" />
                    </div>
                    <div>
                      <h4 class={[
                        "text-xs font-bold sm:text-sm",
                        @theme == "dark" && "text-white",
                        @theme == "light" && "text-slate-900"
                      ]}>
                        Direct Inquire Chat
                      </h4>
                      <p class="text-[10px] font-medium text-emerald-500">
                        Messaging: {(@selected_landlord && @selected_landlord.names) || "Landlord"}
                      </p>
                    </div>
                  </div>
                  <button
                    type="button"
                    phx-click="toggle_chat"
                    class={[
                      "rounded-lg p-1.5 transition",
                      @theme == "dark" && "text-slate-400 hover:bg-slate-800 hover:text-white",
                      @theme == "light" && "text-slate-500 hover:bg-slate-200 hover:text-slate-800"
                    ]}
                  >
                    <.icon name="hero-x-mark" class="size-5" />
                  </button>
                </div>

                <%!-- Messages List --%>
                <div class="flex-1 space-y-3 overflow-y-auto p-4">
                  <div
                    :for={msg <- @chat_messages}
                    class={[
                      "flex flex-col max-w-[88%]",
                      msg.sender == "admin" && "ml-auto items-end",
                      msg.sender != "admin" && "mr-auto items-start"
                    ]}
                  >
                    <span class={[
                      "mb-1 text-[10px]",
                      @theme == "dark" && "text-slate-400",
                      @theme == "light" && "text-slate-500"
                    ]}>
                      {msg.author} • {msg.time}
                    </span>
                    <div class={[
                      "rounded-2xl px-3.5 py-2 text-xs leading-relaxed sm:text-sm",
                      msg.sender == "admin" && "bg-blue-600 text-white rounded-br-none",
                      msg.sender != "admin" && @theme == "dark" &&
                        "bg-slate-800 text-slate-200 border border-slate-700 rounded-bl-none",
                      msg.sender != "admin" && @theme == "light" &&
                        "bg-slate-100 text-slate-800 border border-slate-200 rounded-bl-none"
                    ]}>
                      {msg.text}
                    </div>
                  </div>
                </div>

                <%!-- Input Form --%>
                <form
                  phx-submit="send_message"
                  class={[
                    "border-t p-3",
                    @theme == "dark" && "border-slate-800 bg-[#090d16]",
                    @theme == "light" && "border-slate-200 bg-slate-50"
                  ]}
                >
                  <div class="flex items-center gap-2">
                    <input
                      type="text"
                      name="message"
                      value={@message_text}
                      phx-change="update_message"
                      placeholder="Type message to landlord..."
                      class={[
                        "flex-1 rounded-xl border px-3 py-2 text-xs focus:border-blue-600 focus:outline-none",
                        @theme == "dark" &&
                          "border-slate-700 bg-[#0e1626] text-white placeholder-slate-500",
                        @theme == "light" &&
                          "border-slate-300 bg-white text-slate-900 placeholder-slate-400"
                      ]}
                    />
                    <button
                      type="submit"
                      class="rounded-xl bg-blue-600 p-2 text-white transition hover:bg-blue-700"
                    >
                      <.icon name="hero-paper-airplane" class="size-4" />
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end

  # Sub-component for Approve, Reject, and Inquire Action Buttons
  defp section_action_bar(assigns) do
    ~H"""
    <div class={[
      "mt-6 flex flex-wrap items-center justify-end gap-3 border-t pt-4",
      @theme == "dark" && "border-slate-800",
      @theme == "light" && "border-slate-200"
    ]}>
      <button
        type="button"
        phx-click="reject_section"
        phx-value-section={@section}
        class="flex items-center gap-1.5 rounded-xl border border-rose-500/30 bg-rose-500/10 px-4 py-2 text-xs font-semibold text-rose-600 transition hover:bg-rose-500 hover:text-white"
      >
        <.icon name="hero-x-circle" class="size-4" />
        <span>Reject</span>
      </button>

      <button
        type="button"
        phx-click="open_inquire_modal"
        phx-value-section={@section}
        class="flex items-center gap-1.5 rounded-xl border border-amber-500/30 bg-amber-500/10 px-4 py-2 text-xs font-semibold text-amber-600 transition hover:bg-amber-500 hover:text-white"
      >
        <.icon name="hero-question-mark-circle" class="size-4" />
        <span>Inquire</span>
      </button>

      <button
        type="button"
        phx-click="approve_section"
        phx-value-section={@section}
        class="flex items-center gap-1.5 rounded-xl bg-emerald-600 px-4 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-emerald-700"
      >
        <.icon name="hero-check-circle" class="size-4" />
        <span>Approve</span>
      </button>
    </div>
    """
  end

  # Sub-component for Document Display
  defp doc_card(assigns) do
    ~H"""
    <div class={[
      "overflow-hidden rounded-xl border p-3 text-xs transition",
      @theme == "dark" && "border-slate-800 bg-[#090d16] hover:border-slate-700",
      @theme == "light" && "border-slate-200 bg-slate-50 hover:border-slate-300"
    ]}>
      <div class="mb-2 flex items-center justify-between gap-2">
        <div class="flex min-w-0 items-center gap-1.5">
          <div :if={@url} class="shrink-0 text-emerald-500">
            <.icon name="hero-check-circle" class="size-4" />
          </div>
          <p class={[
            "truncate font-medium",
            @theme == "dark" && "text-slate-200",
            @theme == "light" && "text-slate-800"
          ]}>
            {@title}
          </p>
        </div>

        <span
          :if={@url}
          class="rounded bg-emerald-500/10 px-1.5 py-0.5 text-[10px] font-semibold text-emerald-500"
        >
          Active
        </span>
        <span
          :if={!@url}
          class={[
            "rounded px-1.5 py-0.5 text-[10px]",
            @theme == "dark" && "bg-slate-800 text-slate-400",
            @theme == "light" && "bg-slate-200 text-slate-500"
          ]}
        >
          Missing
        </span>
      </div>

      <div :if={@url} class="mt-2 space-y-2">
        <div class={[
          "group relative overflow-hidden rounded-lg border",
          @theme == "dark" && "border-slate-800 bg-slate-900",
          @theme == "light" && "border-slate-200 bg-white"
        ]}>
          <img
            src={@url}
            alt={@title}
            class="h-32 w-full object-cover transition-transform duration-300 group-hover:scale-105 sm:h-36"
            loading="lazy"
          />
        </div>

        <div class="flex items-center justify-between pt-1">
          <a
            href={@url}
            target="_blank"
            rel="noopener noreferrer"
            class="inline-flex items-center gap-1 font-medium text-blue-600 hover:underline"
          >
            <.icon name="hero-arrow-top-right-on-square" class="size-3.5" /> View in new window
          </a>
        </div>
      </div>

      <p :if={!@url} class="mt-1 text-[11px] text-slate-400">
        No picture uploaded.
      </p>
    </div>
    """
  end

  defp filtered_landlords(landlords, ""), do: landlords

  defp filtered_landlords(landlords, query) do
    q = String.downcase(query)

    Enum.filter(landlords, fn l ->
      String.contains?(String.downcase(l.names || ""), q) or
        String.contains?(String.downcase(l.email || ""), q)
    end)
  end

  defp build_verification_steps(nil, _approved_sections), do: []

  defp build_verification_steps(landlord, _approved_sections) do
    [
      %{
        number: 1,
        title: "Personal details",
        completed?: landlord.personal_details_status == "approved",
        status: landlord.personal_details_status
      },
      %{
        number: 2,
        title: "Identity verification",
        completed?: landlord.identity_status == "approved",
        status: landlord.identity_status
      },
      %{
        number: 3,
        title: "Property details",
        completed?: landlord.property_status == "approved",
        status: landlord.property_status
      },
      %{
        number: 4,
        title: "Billing & payment",
        completed?: landlord.billing_status == "approved",
        status: landlord.billing_status
      },
      %{
        number: 5,
        title: "Final approval",
        completed?: landlord.verification_status == "approved",
        status: landlord.verification_status
      }
    ]
  end

  defp first_name(nil), do: nil

  defp first_name(landlord) do
    landlord.names
    |> to_string()
    |> String.split(" ", trim: true)
    |> List.first()
  end

  defp get_doc_url(nil, _field, _type), do: nil

  defp get_doc_url(landlord, field, type) do
    direct_url = Map.get(landlord, field)

    if direct_url not in [nil, ""] do
      direct_url
    else
      case Enum.find(landlord.documents || [], &(&1.document_type == type)) do
        doc when is_map(doc) ->
          url = Map.get(doc, :file_url) || Map.get(doc, :url)
          if url not in [nil, ""], do: url, else: nil

        _ ->
          nil
      end
    end
  end

  defp detail(nil, _field), do: "Pending"

  defp detail(landlord, field) do
    case Map.get(landlord, field) do
      value when value in [nil, ""] -> "Pending"
      value -> to_string(value)
    end
  end

  defp has_value?(nil, _field), do: false
  defp has_value?(map, field), do: Map.get(map, field) not in [nil, ""]

  defp has_doc?(nil, _type), do: false

  defp has_doc?(landlord, type) do
    Enum.any?(landlord.documents || [], fn doc ->
      doc.document_type == type and
        (Map.get(doc, :file_url) not in [nil, ""] or Map.get(doc, :url) not in [nil, ""])
    end)
  end
end
