defmodule HomeWeb.Process.Text do
  use HomeWeb, :live_view

  alias Home.Accounts

  @process_token_salt "landlord-process"

  @impl true
  def mount(params, _session, socket) do
    landlord = current_landlord(params, socket)
    steps = build_verification_steps(landlord)
    completed_steps_count = Enum.count(steps, & &1.completed?)
    total_steps_count = length(steps)

    progress_percentage =
      if total_steps_count > 0,
        do: round((completed_steps_count / total_steps_count) * 100),
        else: 0

    mock_chat_messages = [
      %{
        sender: "admin",
        author: "Admin Verification Team",
        time: "10:15 AM",
        text: "Hello! We are reviewing your submitted documents. Please reach out here if you have any questions."
      }
    ]

    {:ok,
     socket
     |> assign(:page_title, "Home - Verification Status")
     |> assign(:landlord, landlord)
     |> assign(:greeting, greeting())
     |> assign(:first_name, first_name(landlord))
     |> assign(:steps, steps)
     |> assign(:active_tab, "1")
     |> assign(:completed_steps_count, completed_steps_count)
     |> assign(:total_steps_count, total_steps_count)
     |> assign(:progress_percentage, progress_percentage)
     |> assign(:show_chat, false)
     |> assign(:chat_messages, mock_chat_messages)
     |> assign(:message_text, "")
     |> assign(:theme, "light")}
  end

  @impl true
  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("toggle_theme", _params, socket) do
    new_theme = if socket.assigns.theme == "dark", do: "light", else: "dark"
    {:noreply, assign(socket, :theme, new_theme)}
  end

  def handle_event("toggle_chat", _params, socket) do
    {:noreply, update(socket, :show_chat, &(!&1))}
  end

  def handle_event("update_message", %{"message" => msg}, socket) do
    {:noreply, assign(socket, :message_text, msg)}
  end

  def handle_event("send_message", %{"message" => msg}, socket) when byte_size(msg) > 0 do
    new_msg = %{
      sender: "landlord",
      author: socket.assigns.first_name || "Landlord",
      time: Calendar.strftime(Time.utc_now(), "%I:%M %p"),
      text: msg
    }

    {:noreply,
     socket
     |> update(:chat_messages, fn msgs -> msgs ++ [new_msg] end)
     |> assign(:message_text, "")}
  end

  def handle_event("send_message", _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section
        id="landlord-verification-process"
        class={[
          "fixed inset-0 z-40 overflow-y-auto transition-colors duration-200",
          @theme == "dark" && "bg-[#0b1220] text-slate-100",
          @theme == "light" && "bg-[#f8fafc] text-slate-900"
        ]}
      >
        <div class="min-h-screen">
          <div class="mx-auto flex min-h-screen w-full max-w-5xl flex-col px-4 py-6 sm:px-6 lg:px-8">

            <%!-- Top Centered Branding & Header Content --%>
            <header class={[
              "relative flex flex-col items-center justify-center border-b pb-6 text-center",
              @theme == "dark" && "border-slate-800",
              @theme == "light" && "border-slate-200"
            ]}>
              <%!-- Theme Switcher & Progress Percentage (Top Right) --%>
              <div class="mb-4 flex items-center justify-end gap-3 sm:absolute sm:right-0 sm:top-0 sm:mb-0">
                <button
                  type="button"
                  phx-click="toggle_theme"
                  class={[
                    "flex size-10 items-center justify-center rounded-full border transition active:scale-95",
                    @theme == "dark" && "border-slate-700 bg-[#0e1626] text-amber-400 hover:bg-slate-800",
                    @theme == "light" && "border-slate-300 bg-white text-slate-700 shadow-sm hover:bg-slate-100"
                  ]}
                  title={"Switch to #{if @theme == "dark", do: "Light", else: "Dark"} mode"}
                >
                  <.icon name={if @theme == "dark", do: "hero-sun", else: "hero-moon"} class="size-5" />
                </button>

                <div class="text-right">
                  <p class={[
                    "text-[10px] font-semibold uppercase tracking-wider",
                    @theme == "dark" && "text-slate-400",
                    @theme == "light" && "text-slate-500"
                  ]}>
                    Progress
                  </p>
                  <p class="text-lg font-bold text-emerald-500">{@progress_percentage}%</p>
                </div>
              </div>

              <h1 class={[
                "text-3xl font-extrabold tracking-tight sm:text-4xl md:text-5xl",
                @theme == "dark" && "text-white",
                @theme == "light" && "text-slate-900"
              ]}>
                Home
              </h1>

              <%!-- Dynamic Greeting & Subtitle --%>
              <div class="mt-2 space-y-1">
                <h2 class={[
                  "text-lg font-bold sm:text-xl md:text-2xl",
                  @theme == "dark" && "text-slate-100",
                  @theme == "light" && "text-slate-800"
                ]}>
                  {@greeting}{if @first_name, do: " #{@first_name}", else: ""}
                </h2>
                <p class={[
                  "text-xs sm:text-sm",
                  @theme == "dark" && "text-slate-400",
                  @theme == "light" && "text-slate-600"
                ]}>
                  Your documents have been submitted for verification steps.
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
                    <span class="text-sm font-bold text-emerald-500">{@progress_percentage}%</span>
                  </div>
                  <p class={[
                    "mt-0.5 text-xs font-medium sm:text-sm",
                    @theme == "dark" && "text-slate-300",
                    @theme == "light" && "text-slate-700"
                  ]}>
                    {@completed_steps_count} of {@total_steps_count} Steps Ready
                  </p>
                  <div class={[
                    "mt-2 h-2 w-full overflow-hidden rounded-full",
                    @theme == "dark" && "bg-slate-800",
                    @theme == "light" && "bg-slate-100"
                  ]}>
                    <div
                      class="h-full rounded-full bg-blue-600 transition-all duration-500"
                      style={"width: #{@progress_percentage}%"}
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
                ]}>Select step to view details</span>
              </div>

              <div class="no-scrollbar flex gap-2 overflow-x-auto pb-2">
                <button
                  :for={step <- @steps}
                  type="button"
                  phx-click="select_tab"
                  phx-value-tab={to_string(step.number)}
                  class={[
                    "flex shrink-0 items-center gap-2.5 rounded-xl border px-4 py-2.5 text-xs font-semibold transition",
                    @active_tab == to_string(step.number) && "border-blue-600 bg-blue-600 text-white shadow-md",
                    @active_tab != to_string(step.number) && step.completed? && @theme == "dark" && "border-emerald-500/40 bg-[#0e1626] text-emerald-400 hover:bg-slate-800",
                    @active_tab != to_string(step.number) && step.completed? && @theme == "light" && "border-emerald-500/40 bg-white text-emerald-600 hover:bg-slate-50",
                    @active_tab != to_string(step.number) && !step.completed? && @theme == "dark" && "border-slate-800 bg-[#0e1626] text-slate-400 hover:bg-slate-800",
                    @active_tab != to_string(step.number) && !step.completed? && @theme == "light" && "border-slate-200 bg-white text-slate-600 hover:bg-slate-50"
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
                    ]}>Personal details</h3>
                    <span :if={has_value?(@landlord, :names)} class="flex items-center text-emerald-500">
                      <.icon name="hero-check-circle-solid" class="size-5" />
                    </span>
                  </div>
                  <button type="button" class="text-xs font-semibold text-blue-600 hover:underline">Edit</button>
                </div>

                <div class="mt-4 grid grid-cols-1 gap-y-3.5 gap-x-8 text-sm sm:grid-cols-2">
                  <div class={[
                    "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                    @theme == "dark" && "sm:border-slate-800/60",
                    @theme == "light" && "sm:border-slate-100"
                  ]}>
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Category:</span>
                    <span class={[
                      "font-medium capitalize",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :entity_type)}</span>
                  </div>
                  <div class={[
                    "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                    @theme == "dark" && "sm:border-slate-800/60",
                    @theme == "light" && "sm:border-slate-100"
                  ]}>
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Name:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :names)}</span>
                  </div>
                  <div class={[
                    "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                    @theme == "dark" && "sm:border-slate-800/60",
                    @theme == "light" && "sm:border-slate-100"
                  ]}>
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Email:</span>
                    <span class={[
                      "break-all font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :email)}</span>
                  </div>
                  <div class={[
                    "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                    @theme == "dark" && "sm:border-slate-800/60",
                    @theme == "light" && "sm:border-slate-100"
                  ]}>
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Phone:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :phone)}</span>
                  </div>
                  <div class="flex flex-col sm:flex-row sm:justify-between">
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>WhatsApp:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :whatsapp_phone)}</span>
                  </div>
                  <div class="flex flex-col sm:flex-row sm:justify-between">
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Residence:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :residence_location)}</span>
                  </div>
                </div>
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
                    ]}>Identity verification</h3>
                    <span :if={has_value?(@landlord, :id_number)} class="flex items-center text-emerald-500">
                      <.icon name="hero-check-circle-solid" class="size-5" />
                    </span>
                  </div>
                  <button type="button" class="text-xs font-semibold text-blue-600 hover:underline">Edit</button>
                </div>

                <div class="mt-4 grid grid-cols-1 gap-y-3.5 gap-x-8 text-sm sm:grid-cols-2">
                  <div class={[
                    "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                    @theme == "dark" && "sm:border-slate-800/60",
                    @theme == "light" && "sm:border-slate-100"
                  ]}>
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Doc type:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :id_type)}</span>
                  </div>
                  <div class={[
                    "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                    @theme == "dark" && "sm:border-slate-800/60",
                    @theme == "light" && "sm:border-slate-100"
                  ]}>
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Doc / ID no:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :id_number)}</span>
                  </div>
                  <div class="flex flex-col sm:flex-row sm:justify-between">
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>KRA PIN:</span>
                    <span class={[
                      "font-medium uppercase",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :kra_pin)}</span>
                  </div>
                  <div class="flex flex-col sm:flex-row sm:justify-between">
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Uploads status:</span>
                    <span class="font-medium text-emerald-500">
                      {if has_doc?(@landlord, "id_front") or has_value?(@landlord, :id_front_url), do: "Front attached, ", else: ""}
                      {if has_doc?(@landlord, "id_back") or has_value?(@landlord, :id_back_url), do: "Back attached", else: "Pending uploads"}
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
                      url={get_doc_url(@landlord, :id_front_url, "id_front")}
                      theme={@theme}
                    />
                    <.doc_card
                      title="ID Back Picture"
                      url={get_doc_url(@landlord, :id_back_url, "id_back")}
                      theme={@theme}
                    />
                    <.doc_card
                      title="KRA PIN Certificate"
                      url={get_doc_url(@landlord, :kra_doc_url, "kra_doc")}
                      theme={@theme}
                    />
                  </div>
                </div>
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
                    ]}>Property details</h3>
                    <span :if={has_value?(@landlord, :property_name)} class="flex items-center text-emerald-500">
                      <.icon name="hero-check-circle-solid" class="size-5" />
                    </span>
                  </div>
                  <button type="button" class="text-xs font-semibold text-blue-600 hover:underline">Edit</button>
                </div>

                <div class="mt-4 grid grid-cols-1 gap-y-3.5 gap-x-8 text-sm sm:grid-cols-2">
                  <div class={[
                    "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                    @theme == "dark" && "sm:border-slate-800/60",
                    @theme == "light" && "sm:border-slate-100"
                  ]}>
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Intent:</span>
                    <span class={[
                      "font-medium capitalize",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :listing_purpose)}</span>
                  </div>
                  <div class={[
                    "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                    @theme == "dark" && "sm:border-slate-800/60",
                    @theme == "light" && "sm:border-slate-100"
                  ]}>
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Property name:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :property_name)}</span>
                  </div>
                  <div class={[
                    "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                    @theme == "dark" && "sm:border-slate-800/60",
                    @theme == "light" && "sm:border-slate-100"
                  ]}>
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Location:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :property_location)}</span>
                  </div>
                  <div class={[
                    "flex flex-col sm:flex-row sm:justify-between sm:border-b sm:pb-2",
                    @theme == "dark" && "sm:border-slate-800/60",
                    @theme == "light" && "sm:border-slate-100"
                  ]}>
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Ownership type:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :ownership_type)}</span>
                  </div>
                  <div class="flex flex-col sm:flex-row sm:justify-between">
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Title / LR no:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :lr_number)}</span>
                  </div>
                  <div class="flex flex-col sm:flex-row sm:justify-between">
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Total units:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :total_units)}</span>
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
                      url={get_doc_url(@landlord, :ownership_doc_url, "ownership_doc")}
                      theme={@theme}
                    />
                  </div>
                </div>
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
                    ]}>Billing & payment</h3>
                    <span :if={has_value?(@landlord, :billing_method)} class="flex items-center text-emerald-500">
                      <.icon name="hero-check-circle-solid" class="size-5" />
                    </span>
                  </div>
                  <button type="button" class="text-xs font-semibold text-blue-600 hover:underline">Edit</button>
                </div>

                <div class="mt-4 grid grid-cols-1 gap-y-3.5 gap-x-8 text-sm sm:grid-cols-2">
                  <div class="flex flex-col sm:flex-row sm:justify-between">
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Billing method:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :billing_method)}</span>
                  </div>
                  <div class="flex flex-col sm:flex-row sm:justify-between">
                    <span class={if @theme == "dark", do: "text-slate-400", else: "text-slate-500"}>Billing phone:</span>
                    <span class={[
                      "font-medium",
                      @theme == "dark" && "text-slate-100",
                      @theme == "light" && "text-slate-900"
                    ]}>{detail(@landlord, :billing_phone)}</span>
                  </div>
                </div>
              </div>

            </main>

            <%!-- Responsive Floating Chat Button --%>
            <div class="fixed bottom-4 right-4 z-40 sm:bottom-6 sm:right-6">
              <button
                type="button"
                phx-click="toggle_chat"
                class="flex items-center gap-2 rounded-full bg-blue-600 px-4 py-3 text-xs font-bold text-white shadow-lg transition hover:bg-blue-700 active:scale-95 sm:px-5 sm:py-3.5 sm:text-sm"
              >
                <.icon name="hero-chat-bubble-left-right" class="size-5 sm:size-6" />
                <span>Verification Support</span>
                <span :if={length(@chat_messages) > 0} class="flex size-2 rounded-full bg-emerald-400"></span>
              </button>
            </div>

            <%!-- Verification Support Chat Modal --%>
            <div :if={@show_chat} class="fixed inset-0 z-50 flex flex-col justify-end sm:items-end sm:p-6">
              <div
                class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity"
                phx-click="toggle_chat"
              ></div>

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
                      <.icon name="hero-user-check" class="size-4" />
                    </div>
                    <div>
                      <h4 class={[
                        "text-xs font-bold sm:text-sm",
                        @theme == "dark" && "text-white",
                        @theme == "light" && "text-slate-900"
                      ]}>Verification Support</h4>
                      <p class="text-[10px] font-medium text-emerald-500">Direct Message Admin</p>
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
                      msg.sender == "landlord" && "ml-auto items-end",
                      msg.sender != "landlord" && "mr-auto items-start"
                    ]}
                  >
                    <span class={[
                      "mb-1 text-[10px]",
                      @theme == "dark" && "text-slate-400",
                      @theme == "light" && "text-slate-500"
                    ]}>{msg.author} • {msg.time}</span>
                    <div class={[
                      "rounded-2xl px-3.5 py-2 text-xs leading-relaxed sm:text-sm",
                      msg.sender == "landlord" && "bg-blue-600 text-white rounded-br-none",
                      msg.sender != "landlord" && @theme == "dark" && "bg-slate-800 text-slate-200 border border-slate-700 rounded-bl-none",
                      msg.sender != "landlord" && @theme == "light" && "bg-slate-100 text-slate-800 border border-slate-200 rounded-bl-none"
                    ]}>
                      {msg.text}
                    </div>
                  </div>
                </div>

                <%!-- Input Form --%>
                <form phx-submit="send_message" class={[
                  "border-t p-3",
                  @theme == "dark" && "border-slate-800 bg-[#090d16]",
                  @theme == "light" && "border-slate-200 bg-slate-50"
                ]}>
                  <div class="flex items-center gap-2">
                    <input
                      type="text"
                      name="message"
                      value={@message_text}
                      phx-change="update_message"
                      placeholder="Type a message to admin..."
                      class={[
                        "flex-1 rounded-xl border px-3 py-2 text-xs focus:border-blue-600 focus:outline-none",
                        @theme == "dark" && "border-slate-700 bg-[#0e1626] text-white placeholder-slate-500",
                        @theme == "light" && "border-slate-300 bg-white text-slate-900 placeholder-slate-400"
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

        <span :if={@url} class="rounded bg-emerald-500/10 px-1.5 py-0.5 text-[10px] font-semibold text-emerald-500">
          Active
        </span>
        <span :if={!@url} class={[
          "rounded px-1.5 py-0.5 text-[10px]",
          @theme == "dark" && "bg-slate-800 text-slate-400",
          @theme == "light" && "bg-slate-200 text-slate-500"
        ]}>
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

  defp current_landlord(params, socket) do
    token = params["token"] || params["landlord"]

    cond do
      is_binary(token) ->
        case Phoenix.Token.verify(HomeWeb.Endpoint, @process_token_salt, token, max_age: 604_800) do
          {:ok, landlord_id} -> Accounts.get_landlord_with_documents(landlord_id)
          {:error, _reason} -> nil
        end

      socket.assigns[:current_scope] ->
        case socket.assigns.current_scope do
          %{user: %{id: user_id, role: "landlord"}} -> Accounts.get_landlord_by_user_id(user_id)
          _scope -> nil
        end

      true ->
        nil
    end
  end

  defp build_verification_steps(nil) do
    [
      %{number: 1, title: "Personal details", completed?: false},
      %{number: 2, title: "Identity verification", completed?: false},
      %{number: 3, title: "Property details", completed?: false},
      %{number: 4, title: "Billing & payment", completed?: false}
    ]
  end

  defp build_verification_steps(landlord) do
    step1_ok = landlord.names not in [nil, ""] and landlord.email not in [nil, ""]

    step2_ok =
      (has_value?(landlord, :id_front_url) or has_doc?(landlord, "id_front")) and
        (has_value?(landlord, :id_back_url) or has_doc?(landlord, "id_back")) and
        (has_value?(landlord, :kra_doc_url) or has_doc?(landlord, "kra_doc"))

    step3_ok =
      landlord.property_name not in [nil, ""] and
        (has_value?(landlord, :ownership_doc_url) or has_doc?(landlord, "ownership_doc"))

    step4_ok = has_value?(landlord, :billing_method) or has_value?(landlord, :billing_phone)

    [
      %{number: 1, title: "Personal details", completed?: step1_ok},
      %{number: 2, title: "Identity verification", completed?: step2_ok},
      %{number: 3, title: "Property details", completed?: step3_ok},
      %{number: 4, title: "Billing & payment", completed?: step4_ok}
    ]
  end

  defp greeting do
    hour =
      DateTime.utc_now()
      |> DateTime.add(3, :hour)
      |> Map.fetch!(:hour)

    cond do
      hour < 12 -> "Good morning"
      hour < 17 -> "Good afternoon"
      true -> "Good evening"
    end
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
