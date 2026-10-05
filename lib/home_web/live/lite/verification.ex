defmodule HomeWeb.Verify.Text do
  use HomeWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    landlords = [
      %{
        id: "landlord_1",
        full_name: "John Kamau Omondi",
        email: "john.kamau@example.com",
        phone: "+254 712 345 678",
        whatsapp: "+254 748 172 255",
        residence: "Kisii Marani",
        category: "Individual Landlord",
        doc_type: "National ID",
        id_number: "32984012",
        kra_pin: "A014982736Z",
        intent: "Mixed",
        property_name: "Kilimani Heights",
        location: "Kisii Central",
        ownership_type: "Freehold Title",
        title_lr_no: "LR No: 209/18241",
        total_units: "12",
        billing_method: "M-Pesa",
        billing_phone: "+254 712 345 678",
        submitted_at: "Oct 04, 2026 • 14:20 EAT",
        status: "pending",
        identity_docs: [
          %{
            key: "id_front",
            title: "National ID (Front)",
            doc_no: "ID: 32984012",
            image_url:
              "https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&w=800&q=80",
            notes: "National ID front copy showing full name and ID number."
          },
          %{
            key: "id_back",
            title: "National ID (Back)",
            doc_no: "ID: 32984012",
            image_url:
              "https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=800&q=80",
            notes: "National ID back copy displaying serial and signature."
          },
          %{
            key: "kra_pin",
            title: "KRA PIN Certificate",
            doc_no: "KRA PIN: A014982736Z",
            image_url:
              "https://images.unsplash.com/photo-1568602471122-7832951cc4c5?auto=format&fit=crop&w=800&q=80",
            notes: "Official Kenya Revenue Authority tax PIN document."
          }
        ],
        property_docs: [
          %{
            key: "title_deed",
            title: "Title Deed / Proof of Ownership",
            doc_no: "LR No: 209/18241",
            image_url:
              "https://images.unsplash.com/photo-1560518883-ce09059eeffa?auto=format&fit=crop&w=800&q=80",
            notes: "Registered title deed for land parcel 209/18241."
          }
        ]
      },
      %{
        id: "landlord_2",
        full_name: "Mary Wanjiku Njuguna",
        email: "m.wanjiku@example.com",
        phone: "+254 722 987 654",
        whatsapp: "+254 722 987 654",
        residence: "Nairobi West",
        category: "Individual Landlord",
        doc_type: "National ID",
        id_number: "28471093",
        kra_pin: "A009821451Y",
        intent: "Residential",
        property_name: "Sunrise Haven",
        location: "Nairobi",
        ownership_type: "Leasehold Title",
        title_lr_no: "LR No: 104/552",
        total_units: "8",
        billing_method: "M-Pesa",
        billing_phone: "+254 722 987 654",
        submitted_at: "Oct 04, 2026 • 11:05 EAT",
        status: "pending",
        identity_docs: [
          %{
            key: "id_front",
            title: "National ID (Front)",
            doc_no: "ID: 28471093",
            image_url:
              "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80",
            notes: "Front side national identity photo."
          },
          %{
            key: "kra_pin",
            title: "KRA PIN Certificate",
            doc_no: "KRA PIN: A009821451Y",
            image_url:
              "https://images.unsplash.com/photo-1450133064473-71024230f91b?auto=format&fit=crop&w=800&q=80",
            notes: "Tax registration PIN certificate."
          }
        ],
        property_docs: []
      }
    ]

    initial_messages = %{
      "landlord_1" => [
        %{sender: "system", text: "Automated: Landlord account registered.", time: "14:20"},
        %{
          sender: "landlord",
          text: "Hello Admin, I have submitted all requested verification details.",
          time: "14:22"
        }
      ]
    }

    {:ok,
     socket
     |> assign(:page_title, "Landlord Onboarding Portal")
     |> assign(:theme, "dark")
     |> assign(:mobile_tab, "documents")
     |> assign(:landlords, landlords)
     |> assign(:selected_landlord_id, "landlord_1")
     |> assign(:active_step, 1)
     |> assign(:chat_open, false)
     |> assign(:chat_messages, initial_messages)
     |> assign(:new_message, "")}
  end

  @impl true
  def handle_event("toggle_theme", _params, socket) do
    new_theme = if socket.assigns.theme == "dark", do: "light", else: "dark"
    {:noreply, assign(socket, :theme, new_theme)}
  end

  @impl true
  def handle_event("switch_mobile_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :mobile_tab, tab)}
  end

  @impl true
  def handle_event("select_landlord", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:selected_landlord_id, id)
     |> assign(:active_step, 1)
     |> assign(:mobile_tab, "documents")}
  end

  @impl true
  def handle_event("select_step", %{"step" => step}, socket) do
    step_num = String.to_integer(step)
    {:noreply, assign(socket, :active_step, step_num)}
  end

  @impl true
  def handle_event("open_chat", _params, socket) do
    {:noreply, assign(socket, :chat_open, true)}
  end

  @impl true
  def handle_event("close_chat", _params, socket) do
    {:noreply, assign(socket, :chat_open, false)}
  end

  @impl true
  def handle_event("update_message", %{"value" => val}, socket) do
    {:noreply, assign(socket, :new_message, val)}
  end

  @impl true
  def handle_event("send_chat", %{"message" => text}, socket) do
    trimmed = String.trim(text)

    if trimmed == "" do
      {:noreply, socket}
    else
      id = socket.assigns.selected_landlord_id
      new_msg = %{sender: "admin", text: trimmed, time: "Just now"}
      current_list = Map.get(socket.assigns.chat_messages, id, [])
      updated_map = Map.put(socket.assigns.chat_messages, id, current_list ++ [new_msg])

      {:noreply,
       socket
       |> assign(:chat_messages, updated_map)
       |> assign(:new_message, "")
       |> put_flash(:info, "Message sent to landlord.")}
    end
  end

  @impl true
  def handle_event("approve_landlord", %{"id" => id}, socket) do
    updated_landlords =
      Enum.map(socket.assigns.landlords, fn l ->
        if l.id == id, do: Map.put(l, :status, "approved"), else: l
      end)

    {:noreply,
     socket
     |> assign(:landlords, updated_landlords)
     |> put_flash(:info, "Landlord details verified successfully.")}
  end

  @impl true
  def render(assigns) do
    selected =
      Enum.find(assigns.landlords, &(&1.id == assigns.selected_landlord_id)) ||
        hd(assigns.landlords)

    current_chat = Map.get(assigns.chat_messages, selected.id, [])

    theme_bg =
      if assigns.theme == "dark",
        do: "bg-[#0A0B14] text-slate-100",
        else: "bg-[#F8FAFC] text-slate-900"

    sidebar_bg =
      if assigns.theme == "dark",
        do: "bg-[#0F101D] border-slate-800/80",
        else: "bg-white border-slate-200 shadow-sm"

    panel_bg = if assigns.theme == "dark", do: "bg-[#121324]", else: "bg-white"

    card_bg =
      if assigns.theme == "dark",
        do: "bg-[#16182E] border-slate-800",
        else: "bg-white border-slate-200 shadow-sm"

    sub_card_bg =
      if assigns.theme == "dark",
        do: "bg-[#1B1D36] border-slate-700/50",
        else: "bg-slate-50 border-slate-200"

    border_col = if assigns.theme == "dark", do: "border-slate-800", else: "border-slate-200"
    text_muted = if assigns.theme == "dark", do: "text-slate-400", else: "text-slate-500"

    assigns =
      assigns
      |> assign(:landlord, selected)
      |> assign(:current_chat, current_chat)
      |> assign(:theme_bg, theme_bg)
      |> assign(:sidebar_bg, sidebar_bg)
      |> assign(:panel_bg, panel_bg)
      |> assign(:card_bg, card_bg)
      |> assign(:sub_card_bg, sub_card_bg)
      |> assign(:border_col, border_col)
      |> assign(:text_muted, text_muted)

    ~H"""
    <div class={[
      "h-screen w-full flex font-sans overflow-hidden transition-colors duration-200",
      @theme_bg
    ]}>
      <%!-- LEFT SIDEBAR NAVIGATION --%>
      <aside class={[
        "w-56 md:w-60 flex-shrink-0 border-r flex flex-col justify-between p-4 z-20 hidden md:flex",
        @sidebar_bg
      ]}>
        <div class="space-y-6">
          <div class="flex items-center gap-3 px-1">
            <div class="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center font-bold text-white text-xs shadow-md shadow-indigo-600/30">
              L
            </div>
            <div>
              <h1 class="text-xs font-bold leading-none tracking-tight">Operations Panel</h1>
              <span class={["text-[10px] block mt-0.5", @text_muted]}>henry masita</span>
            </div>
          </div>

          <nav class="space-y-1">
            <a
              href="#"
              class={[
                "flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-medium transition hover:bg-indigo-500/10 hover:text-indigo-400",
                @text_muted
              ]}
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
                />
              </svg>
              Overview
            </a>
            <a
              href="#"
              class={[
                "flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-medium transition hover:bg-indigo-500/10 hover:text-indigo-400",
                @text_muted
              ]}
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                />
              </svg>
              Landlords
            </a>
            <a
              href="#"
              class="flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-bold bg-indigo-600 text-white shadow-md shadow-indigo-600/30"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Onboarding
            </a>
            <a
              href="#"
              class={[
                "flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-medium transition hover:bg-indigo-500/10 hover:text-indigo-400",
                @text_muted
              ]}
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
                />
              </svg>
              Settings
            </a>
          </nav>
        </div>

        <div class={["border-t pt-4 space-y-3", @border_col]}>
          <div class="flex items-center justify-between text-xs font-medium">
            <span class={@text_muted}>Appearance</span>
            <button
              phx-click="toggle_theme"
              class="p-1.5 rounded-lg border transition hover:scale-105 flex items-center gap-1.5"
            >
              <%= if @theme == "dark" do %>
                <svg class="w-4 h-4 text-amber-400" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 100 2h1z"
                    clip-rule="evenodd"
                  />
                </svg>
                <span class="text-[10px] font-bold text-amber-400">Light</span>
              <% else %>
                <svg class="w-4 h-4 text-indigo-600" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                </svg>
                <span class="text-[10px] font-bold text-indigo-600">Dark</span>
              <% end %>
            </button>
          </div>
          <button class="text-xs font-bold text-rose-400 hover:text-rose-300 block w-full text-left">
            Log out
          </button>
        </div>
      </aside>

      <%!-- MAIN CONTENT AREA --%>
      <div class="flex-1 flex flex-col overflow-hidden">
        <%!-- TOP BAR --%>
        <header class={[
          "h-14 border-b flex items-center justify-between px-4 lg:px-6 flex-shrink-0 z-10",
          @panel_bg,
          @border_col
        ]}>
          <div class="flex items-center gap-3">
            <div class="w-7 h-7 rounded-lg bg-indigo-600 flex items-center justify-center font-bold text-white text-xs shadow-md shadow-indigo-600/30 md:hidden">
              L
            </div>
            <div>
              <h1 class="text-xs font-bold leading-none">Onboarding Details</h1>
              <span class={["text-[10px] hidden sm:inline-block", @text_muted]}>
                Inspect collected landlord registration information
              </span>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <div class="flex md:hidden bg-slate-800/40 p-1 rounded-lg text-xs font-semibold">
              <button
                phx-click="switch_mobile_tab"
                phx-value-tab="queue"
                class={[
                  "px-2.5 py-1 rounded-md text-[11px]",
                  if(@mobile_tab == "queue",
                    do: "bg-indigo-600 text-white font-bold",
                    else: @text_muted
                  )
                ]}
              >
                Queue ({length(@landlords)})
              </button>
              <button
                phx-click="switch_mobile_tab"
                phx-value-tab="documents"
                class={[
                  "px-2.5 py-1 rounded-md text-[11px]",
                  if(@mobile_tab == "documents",
                    do: "bg-indigo-600 text-white font-bold",
                    else: @text_muted
                  )
                ]}
              >
                Details
              </button>
            </div>

            <button
              phx-click="toggle_theme"
              class={[
                "p-2 rounded-xl border transition flex items-center justify-center",
                @border_col,
                if(@theme == "dark",
                  do: "bg-[#181A35] hover:bg-[#202347]",
                  else: "bg-slate-100 hover:bg-slate-200"
                )
              ]}
            >
              <%= if @theme == "dark" do %>
                <svg class="w-4 h-4 text-amber-400" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 100 2h1z"
                    clip-rule="evenodd"
                  />
                </svg>
              <% else %>
                <svg class="w-4 h-4 text-indigo-600" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
                </svg>
              <% end %>
            </button>
          </div>
        </header>

        <%!-- WORKSPACE --%>
        <div class="flex-1 flex flex-col md:flex-row overflow-hidden">
          <%!-- LEFT COLUMN: LANDLORD QUEUE --%>
          <aside class={[
            "w-full md:w-72 lg:w-80 border-r flex flex-col flex-shrink-0 overflow-hidden transition-all",
            @panel_bg,
            @border_col,
            if(@mobile_tab == "queue", do: "flex", else: "hidden md:flex")
          ]}>
            <div class={[
              "p-3.5 border-b flex-shrink-0 flex items-center justify-between",
              @border_col
            ]}>
              <div>
                <h2 class="text-xs font-bold uppercase tracking-wider text-indigo-400">
                  Landlord Queue
                </h2>
                <p class={["text-[11px] mt-0.5", @text_muted]}>Select landlord to inspect details</p>
              </div>
              <span class={["text-xs px-2 py-0.5 rounded-lg font-bold", @sub_card_bg, @text_muted]}>
                {length(@landlords)} Total
              </span>
            </div>

            <div class="flex-1 overflow-y-auto p-3 space-y-2">
              <%= for l <- @landlords do %>
                <div
                  phx-click="select_landlord"
                  phx-value-id={l.id}
                  class={[
                    "p-3 rounded-xl border cursor-pointer transition flex items-center justify-between",
                    if(@selected_landlord_id == l.id,
                      do: "bg-indigo-600/15 border-indigo-500 text-indigo-300 shadow-sm",
                      else: "border-slate-800 hover:border-indigo-500/30"
                    )
                  ]}
                >
                  <div>
                    <div class="flex items-center gap-2">
                      <span class="text-xs font-bold">{l.full_name}</span>
                      <%= if @selected_landlord_id == l.id do %>
                        <span class="text-[9px] text-indigo-300 bg-indigo-600/30 px-1.5 py-0.2 rounded font-mono">
                          ACTIVE
                        </span>
                      <% end %>
                    </div>
                    <div class={["text-[11px] font-mono mt-0.5", @text_muted]}>
                      ID: {l.id_number}
                    </div>
                  </div>

                  <div>
                    <%= case l.status do %>
                      <% "approved" -> %>
                        <span class="text-[10px] text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20 font-bold">
                          Approved
                        </span>
                      <% "rejected" -> %>
                        <span class="text-[10px] text-rose-400 bg-rose-500/10 px-2 py-0.5 rounded-full border border-rose-500/20 font-bold">
                          Rejected
                        </span>
                      <% _ -> %>
                        <span class="text-[10px] text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded-full border border-amber-500/20 font-bold">
                          Pending
                        </span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </aside>

          <%!-- RIGHT COLUMN: DYNAMIC 4-STEP INLINE DISPLAY --%>
          <main class={[
            "flex-1 flex flex-col overflow-hidden",
            if(@mobile_tab == "documents", do: "flex", else: "hidden md:flex")
          ]}>
            <%!-- TOP STEP TABS (CLEANER, NON-COMPRESSED MOBILE SCROLLING) --%>
            <div class={[
              "px-3 py-2.5 border-b flex items-center justify-between gap-2 flex-shrink-0",
              @panel_bg,
              @border_col
            ]}>
              <div class="flex items-center gap-2 overflow-x-auto w-full scrollbar-none py-0.5">
                <%= for {num, title} <- [{1, "Personal Details"}, {2, "Identity Docs"}, {3, "Property Info"}, {4, "Payout Info"}] do %>
                  <button
                    phx-click="select_step"
                    phx-value-step={num}
                    class={[
                      "flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-semibold transition cursor-pointer flex-shrink-0 whitespace-nowrap",
                      if(@active_step == num,
                        do:
                          "bg-indigo-600 border-indigo-500 text-white shadow-sm shadow-indigo-600/30 font-bold",
                        else:
                          "border border-slate-800 bg-slate-800/40 hover:bg-slate-800 text-slate-300"
                      )
                    ]}
                  >
                    <span class={[
                      "w-4 h-4 rounded-full text-[10px] font-bold flex items-center justify-center flex-shrink-0",
                      if(@active_step == num,
                        do: "bg-white text-indigo-700",
                        else: "bg-indigo-500/30 text-indigo-300"
                      )
                    ]}>
                      {num}
                    </span>
                    <span>{title}</span>
                  </button>
                <% end %>
              </div>

              <div class="text-[11px] font-medium text-indigo-400 hidden lg:block whitespace-nowrap pl-2">
                Landlord: <strong class="text-slate-200">{@landlord.full_name}</strong>
              </div>
            </div>

            <%!-- STEP CONTENT BODY (RENDERED INLINE BELOW STEPS) --%>
            <div class="flex-1 overflow-y-auto p-3.5 sm:p-5 space-y-4">
              <%!-- STEP 1: PERSONAL DETAILS --%>
              <%= if @active_step == 1 do %>
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <h2 class="text-xs font-bold uppercase tracking-wider text-indigo-400">
                        Personal Details
                      </h2>
                      <p class={["text-[11px]", @text_muted]}>
                        Primary contact and residence information
                      </p>
                    </div>
                    <span class="text-[10px] text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded font-bold border border-emerald-500/20">
                      Step 1 of 4
                    </span>
                  </div>

                  <div class={[
                    "p-4 sm:p-5 rounded-2xl border space-y-4 shadow-sm",
                    @card_bg,
                    @border_col
                  ]}>
                    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4 text-xs">
                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Category
                        </span>
                        <strong class="text-sm">{@landlord.category}</strong>
                      </div>

                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Full Name
                        </span>
                        <strong class="text-sm text-indigo-300">{@landlord.full_name}</strong>
                      </div>

                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Email Address
                        </span>
                        <strong class="text-sm font-mono break-all">{@landlord.email}</strong>
                      </div>

                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Phone Number
                        </span>
                        <strong class="text-sm font-mono">{@landlord.phone}</strong>
                      </div>

                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          WhatsApp Contact
                        </span>
                        <strong class="text-sm font-mono">{@landlord.whatsapp}</strong>
                      </div>

                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Residence / Location
                        </span>
                        <strong class="text-sm">{@landlord.residence}</strong>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>

              <%!-- STEP 2: IDENTITY VERIFICATION --%>
              <%= if @active_step == 2 do %>
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <h2 class="text-xs font-bold uppercase tracking-wider text-indigo-400">
                        Identity Verification
                      </h2>
                      <p class={["text-[11px]", @text_muted]}>
                        National ID card and KRA PIN documents
                      </p>
                    </div>
                    <span class="text-[10px] text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded font-bold border border-emerald-500/20">
                      Step 2 of 4
                    </span>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <%= for doc <- @landlord.identity_docs do %>
                      <div class={[
                        "rounded-xl border overflow-hidden shadow-sm flex flex-col justify-between",
                        @card_bg,
                        @border_col
                      ]}>
                        <div class={[
                          "px-3 py-2 border-b flex items-center justify-between",
                          @panel_bg,
                          @border_col
                        ]}>
                          <div>
                            <h3 class="text-xs font-bold truncate">{doc.title}</h3>
                            <span class="text-[10px] font-mono text-indigo-400">{doc.doc_no}</span>
                          </div>
                          <a
                            href={doc.image_url}
                            target="_blank"
                            class="px-2 py-0.5 rounded text-[10px] font-semibold text-indigo-400 bg-indigo-500/10 hover:bg-indigo-500/20 border border-indigo-500/20"
                          >
                            Open ↗
                          </a>
                        </div>

                        <%!-- Compact Document Image View --%>
                        <div class="p-3 flex items-center justify-center bg-black/30 h-40">
                          <img
                            src={doc.image_url}
                            alt={doc.title}
                            class="max-h-36 w-auto object-contain rounded-lg border border-slate-700/40 shadow-sm"
                          />
                        </div>

                        <div class={[
                          "px-3 py-2 border-t text-[11px] flex items-center justify-between gap-2",
                          @border_col,
                          @text_muted
                        ]}>
                          <span class="truncate">{doc.notes}</span>
                          <button
                            phx-click="open_chat"
                            class="text-indigo-400 hover:underline text-[10px] font-semibold flex-shrink-0"
                          >
                            Flag Issue
                          </button>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%!-- STEP 3: PROPERTY DETAILS & OWNERSHIP DOCS --%>
              <%= if @active_step == 3 do %>
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <h2 class="text-xs font-bold uppercase tracking-wider text-indigo-400">
                        Property Details & Title
                      </h2>
                      <p class={["text-[11px]", @text_muted]}>
                        Land parcel metadata and ownership proof
                      </p>
                    </div>
                    <span class="text-[10px] text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded font-bold border border-emerald-500/20">
                      Step 3 of 4
                    </span>
                  </div>

                  <div class={[
                    "p-4 sm:p-5 rounded-2xl border space-y-4 shadow-sm",
                    @card_bg,
                    @border_col
                  ]}>
                    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4 text-xs">
                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Property Name
                        </span>
                        <strong class="text-sm font-bold text-indigo-300">
                          {@landlord.property_name}
                        </strong>
                      </div>

                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Intent / Category
                        </span>
                        <strong class="text-sm">{@landlord.intent}</strong>
                      </div>

                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Location
                        </span>
                        <strong class="text-sm">{@landlord.location}</strong>
                      </div>

                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Ownership Type
                        </span>
                        <strong class="text-sm">{@landlord.ownership_type}</strong>
                      </div>

                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Title / LR Number
                        </span>
                        <strong class="text-sm font-mono text-indigo-400">
                          {@landlord.title_lr_no}
                        </strong>
                      </div>

                      <div class={["p-3.5 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Total Units
                        </span>
                        <strong class="text-sm">{@landlord.total_units} Units</strong>
                      </div>
                    </div>
                  </div>

                  <%!-- Property Proof Document Cards --%>
                  <%= if length(@landlord.property_docs) > 0 do %>
                    <h3 class="text-xs font-bold mt-4">Ownership Proof Documents</h3>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <%= for doc <- @landlord.property_docs do %>
                        <div class={[
                          "rounded-xl border overflow-hidden shadow-sm flex flex-col justify-between",
                          @card_bg,
                          @border_col
                        ]}>
                          <div class={[
                            "px-3 py-2 border-b flex items-center justify-between",
                            @panel_bg,
                            @border_col
                          ]}>
                            <div>
                              <h3 class="text-xs font-bold truncate">{doc.title}</h3>
                              <span class="text-[10px] font-mono text-indigo-400">{doc.doc_no}</span>
                            </div>
                            <a
                              href={doc.image_url}
                              target="_blank"
                              class="px-2 py-0.5 rounded text-[10px] font-semibold text-indigo-400 bg-indigo-500/10 hover:bg-indigo-500/20 border border-indigo-500/20"
                            >
                              Open ↗
                            </a>
                          </div>

                          <div class="p-3 flex items-center justify-center bg-black/30 h-40">
                            <img
                              src={doc.image_url}
                              alt={doc.title}
                              class="max-h-36 w-auto object-contain rounded-lg border border-slate-700/40 shadow-sm"
                            />
                          </div>

                          <div class={[
                            "px-3 py-2 border-t text-[11px] flex items-center justify-between gap-2",
                            @border_col,
                            @text_muted
                          ]}>
                            <span class="truncate">{doc.notes}</span>
                            <button
                              phx-click="open_chat"
                              class="text-indigo-400 hover:underline text-[10px] font-semibold flex-shrink-0"
                            >
                              Flag Issue
                            </button>
                          </div>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>

              <%!-- STEP 4: PAYOUT & BILLING DETAILS --%>
              <%= if @active_step == 4 do %>
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <h2 class="text-xs font-bold uppercase tracking-wider text-indigo-400">
                        Payout & Billing Details
                      </h2>
                      <p class={["text-[11px]", @text_muted]}>
                        Configured payment collection and disbursement parameters
                      </p>
                    </div>
                    <span class="text-[10px] text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded font-bold border border-emerald-500/20">
                      Step 4 of 4
                    </span>
                  </div>

                  <div class={[
                    "p-4 sm:p-5 rounded-2xl border space-y-4 shadow-sm",
                    @card_bg,
                    @border_col
                  ]}>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
                      <div class={["p-4 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          Billing Method
                        </span>
                        <strong class="text-base text-indigo-300">{@landlord.billing_method}</strong>
                      </div>

                      <div class={["p-4 rounded-xl border", @sub_card_bg, @border_col]}>
                        <span class={["text-[10px] block uppercase font-mono mb-1", @text_muted]}>
                          M-Pesa / Billing Phone
                        </span>
                        <strong class="text-base font-mono">{@landlord.billing_phone}</strong>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <%!-- BOTTOM ACTION BAR --%>
            <div class={[
              "p-3.5 border-t flex flex-col sm:flex-row items-center justify-between gap-3 flex-shrink-0",
              @panel_bg,
              @border_col
            ]}>
              <div>
                <h4 class="text-xs font-bold">Verification Actions</h4>
                <p class={["text-[11px]", @text_muted]}>
                  Approve or query landlord submitted details
                </p>
              </div>

              <div class="flex items-center gap-2 w-full sm:w-auto">
                <button
                  phx-click="open_chat"
                  class="flex-1 sm:flex-initial px-4 py-2 rounded-xl text-xs font-bold text-amber-300 bg-amber-500/10 border border-amber-500/20 hover:bg-amber-500/20 transition flex items-center justify-center gap-1.5"
                >
                  💬 Text Landlord
                </button>

                <%= if @landlord.status != "approved" do %>
                  <button
                    phx-click="approve_landlord"
                    phx-value-id={@landlord.id}
                    class="flex-1 sm:flex-initial px-5 py-2 rounded-xl text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-500 shadow-sm transition"
                  >
                    Approve Landlord
                  </button>
                <% else %>
                  <span class="px-4 py-2 rounded-xl text-xs font-bold text-emerald-400 bg-emerald-500/10 border border-emerald-500/20">
                    ✓ Verified
                  </span>
                <% end %>
              </div>
            </div>
          </main>
        </div>
      </div>

      <%!-- LANDLORD CHAT MODAL --%>
      <%= if @chat_open do %>
        <div class="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-3 sm:p-4">
          <div class={[
            "w-full max-w-lg rounded-2xl border shadow-2xl flex flex-col max-h-[85vh] overflow-hidden",
            @panel_bg,
            @border_col
          ]}>
            <div class={["p-4 border-b flex items-center justify-between", @border_col]}>
              <div class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-full bg-indigo-600/20 text-indigo-300 font-bold flex items-center justify-center text-xs border border-indigo-500/30">
                  {String.slice(@landlord.full_name, 0, 2)}
                </div>
                <div>
                  <h3 class="text-xs font-bold">{@landlord.full_name}</h3>
                  <p class={["text-[10px]", @text_muted]}>Phone: {@landlord.phone}</p>
                </div>
              </div>

              <button phx-click="close_chat" class="p-1 rounded-lg text-slate-400 hover:text-white">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div class="flex-1 p-4 overflow-y-auto space-y-3 bg-black/20 min-h-[200px]">
              <%= for msg <- @current_chat do %>
                <div class={[
                  "flex flex-col max-w-[85%]",
                  if(msg.sender == "admin", do: "ml-auto items-end", else: "mr-auto items-start")
                ]}>
                  <div class={[
                    "p-3 rounded-2xl text-xs shadow-sm",
                    case msg.sender do
                      "admin" ->
                        "bg-indigo-600 text-white rounded-br-none"

                      "landlord" ->
                        "bg-slate-800 text-slate-200 rounded-bl-none border border-slate-700/40"

                      _ ->
                        "bg-slate-800/60 text-slate-400 italic text-[11px] self-center my-1"
                    end
                  ]}>
                    {msg.text}
                  </div>
                  <span class={["text-[9px] mt-1 px-1", @text_muted]}>
                    {msg.time}
                  </span>
                </div>
              <% end %>
            </div>

            <form phx-submit="send_chat" class={["p-3 border-t flex items-center gap-2", @border_col]}>
              <input
                type="text"
                name="message"
                value={@new_message}
                phx-change="update_message"
                placeholder="Type message to landlord..."
                class={[
                  "flex-1 px-3.5 py-2 rounded-xl text-xs border focus:outline-none focus:border-indigo-500",
                  @sub_card_bg,
                  @border_col
                ]}
              />
              <button
                type="submit"
                class="px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold transition"
              >
                Send
              </button>
            </form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
