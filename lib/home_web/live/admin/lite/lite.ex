defmodule HomeWeb.Text.Lite do
  use HomeWeb, :live_view
  alias Home.Accounts
@impl true
def mount(_params, _session, socket) do
  current_user = socket.assigns.current_scope.user

  if current_user.role == "admin" do
    {:ok,
     socket
     |> assign(:theme, "dark")
     |> assign(:invites, Accounts.list_admin_lite_invites())
     |> assign(:mobile_menu_open, false)
     |> assign(:generated_link, nil)
     |> assign(:link_copied, false)
     |> assign(:link_type, "invite")
     |> assign(:link_role, "staff")
     |> assign(:stats, %{
       active_units: 42,
       pending_requests: 7,
       staff_online: 12,
       total_leads: 128
     })}
  else
    {:ok,
     socket
     |> put_flash(:error, "You are not authorized to access Admin Lite.")
     |> redirect(to: ~p"/admin")}
  end
end

@impl true
def handle_event("toggle_suspend_invite", %{"id" => id}, socket) do
  case Accounts.toggle_suspend_invite(id) do
    {:ok, _invite} ->
      {:noreply,
       socket
       |> put_flash(:info, "Invite status updated.")
       |> assign(:invites, Accounts.list_admin_lite_invites())}

    {:error, _} ->
      {:noreply, put_flash(socket, :error, "Failed to update invite.")}
  end
end

@impl true
def handle_event("revoke_invite", %{"id" => id}, socket) do
  case Accounts.delete_admin_lite_invite(id) do
    {:ok, _invite} ->
      {:noreply,
       socket
       |> put_flash(:info, "Invite link revoked successfully 🔥")
       |> assign(:invites, Accounts.list_admin_lite_invites())}

    {:error, _} ->
      {:noreply, put_flash(socket, :error, "Could not revoke invite.")}
  end
end

  @impl true
  def handle_event("toggle_mobile_menu", _params, socket) do
    {:noreply, assign(socket, :mobile_menu_open, !socket.assigns.mobile_menu_open)}
  end

  @impl true
  def handle_event("toggle_theme", _, socket) do
    new_theme = if socket.assigns.theme == "dark", do: "light", else: "dark"

    {:noreply,
     socket
     |> assign(:theme, new_theme)
     |> push_event("set_global_theme", %{theme: new_theme})}
  end

  @impl true
  def handle_event("restore_theme", %{"theme" => theme}, socket)
      when theme in ["dark", "light"] do
    {:noreply, assign(socket, :theme, theme)}
  end

  # @impl true
  # def handle_event("restore_theme", _params, socket), do: {:noreply, socket}

  @impl true
def handle_event("generate_link", %{"email" => email}, socket) do
  current_user = socket.assigns.current_scope.user

  case Accounts.create_admin_lite_invite(current_user, email) do
    {:ok, invite} ->
      generated_url =
        "#{HomeWeb.Endpoint.url()}/verification?token=#{invite.token}"

      {:noreply,
       socket
       |> assign(:generated_link, generated_url)
       # Refresh the invites list so the table updates immediately
       |> assign(:invites, Accounts.list_admin_lite_invites())
       |> assign(:link_copied, false)}

    {:error, :unauthorized} ->
      {:noreply, put_flash(socket, :error, "You are not authorized to create Admin Lite invites.")}

    {:error, _changeset} ->
      {:noreply, put_flash(socket, :error, "Could not create the invite. Please check the email.")}
  end
end

  @impl true
def handle_event("copy_link", %{"url" => url}, socket) do
  {:noreply,
   socket
   |> assign(:link_copied, true)
   |> push_event("copy-to-clipboard", %{text: url})}
end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="lite-admin"
      phx-hook="HouseFinder"
      class={[
        "min-h-screen transition-colors duration-200 font-sans",
        @theme == "dark" && "bg-slate-950 text-slate-100",
        @theme == "light" && "bg-slate-50 text-slate-800"
      ]}
    >
      <!-- Top Header / Bar -->
      <header class={[
        "sticky top-0 z-30 border-b px-4 sm:px-6 py-3 flex items-center justify-between backdrop-blur-md",
        @theme == "dark" && "bg-slate-900/80 border-slate-800",
        @theme == "light" && "bg-white/80 border-slate-200"
      ]}>
        <div class="flex items-center gap-3">
          <button
            phx-click="toggle_mobile_menu"
            type="button"
            class="md:hidden p-2 rounded-lg text-slate-400 hover:text-slate-200 hover:bg-slate-800/50 transition"
            aria-label="Toggle Navigation"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>

          <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-xl bg-indigo-600 flex items-center justify-center font-black text-white text-sm shadow-md shadow-indigo-500/20">
              HF
            </div>
            <span class="font-bold text-lg tracking-tight">Lite Admin</span>
          </div>
        </div>

        <!-- Dark / Light Theme Toggle -->
        <button
          phx-click="toggle_theme"
          type="button"
          class={[
            "flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold border transition shadow-sm",
            @theme == "dark" && "bg-slate-800 border-slate-700 text-amber-400 hover:bg-slate-700",
            @theme == "light" && "bg-slate-100 border-slate-200 text-slate-700 hover:bg-slate-200"
          ]}
        >
          <svg :if={@theme == "dark"} class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
          <svg :if={@theme == "light"} class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
          </svg>
          <span class="hidden sm:inline"><%= if @theme == "dark", do: "Light Mode", else: "Dark Mode" %></span>
        </button>
      </header>

      <div class="flex">
        <!-- Desktop Sidebar -->
        <aside class={[
          "hidden md:block w-64 min-h-[calc(100vh-57px)] border-r p-4 space-y-1 shrink-0",
          @theme == "dark" && "bg-slate-900/50 border-slate-800",
          @theme == "light" && "bg-white border-slate-200"
        ]}>
          <.nav_contents theme={@theme} />
        </aside>

        <!-- Mobile Drawer Sidebar -->
        <div :if={@mobile_menu_open} class="relative z-40 md:hidden">
          <div class="fixed inset-0 bg-slate-950/60 backdrop-blur-sm" phx-click="toggle_mobile_menu"></div>
          <aside class={[
            "fixed inset-y-0 left-0 w-64 border-r p-4 space-y-1 shadow-2xl flex flex-col justify-between",
            @theme == "dark" && "bg-slate-900 border-slate-800",
            @theme == "light" && "bg-white border-slate-200"
          ]}>
            <div>
              <div class="flex items-center justify-between mb-4 pb-2 border-b border-slate-700/50">
                <span class="font-bold text-sm uppercase tracking-wider text-slate-400">Navigation</span>
                <button phx-click="toggle_mobile_menu" class="p-1 text-slate-400 hover:text-slate-200">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <.nav_contents theme={@theme} />
            </div>
          </aside>
        </div>

        <!-- Main Content Area -->
        <main class="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto space-y-6">
          <!-- Overview Banner & Stats -->
          <div class="space-y-4">
            <div>
              <h1 class="text-2xl font-bold tracking-tight">System Overview</h1>
              <p class="text-sm text-slate-400">Monitor operations and generate quick access links for staff.</p>
            </div>

            <!-- Stats Grid -->
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <.stat_card title="Active Listings" value={@stats.active_units} icon="building" theme={@theme} />
              <.stat_card title="Pending Verification" value={@stats.pending_requests} icon="clock" theme={@theme} />
              <.stat_card title="Active Staff" value={@stats.staff_online} icon="users" theme={@theme} />
              <.stat_card title="Client Inquiries" value={@stats.total_leads} icon="chat" theme={@theme} />
            </div>
          </div>

          <!-- Feature Section: Link Generation Card & Activity Feed -->
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Link Generation Card -->
            <div class={[
              "lg:col-span-2 p-6 rounded-2xl border transition-all space-y-5",
              @theme == "dark" && "bg-slate-900 border-slate-800",
              @theme == "light" && "bg-white border-slate-200 shadow-sm"
            ]}>
              <div class="flex items-center justify-between border-b pb-4 border-slate-700/30">
                <div class="flex items-center gap-3">
                  <div class="p-2.5 rounded-xl bg-indigo-600/10 text-indigo-500 border border-indigo-500/20">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                    </svg>
                  </div>
                  <div>
                    <h2 class="text-base font-bold tracking-tight">Access Link Generator</h2>
                    <p class="text-xs text-slate-400">Create secure, single-use invite or onboarding links.</p>
                  </div>
                </div>
              </div>

              <!-- Link Form -->
      <form phx-submit="generate_link" class="space-y-4">
            <div>
             <label class="block text-xs font-semibold text-slate-400 mb-1.5 uppercase tracking-wider">
             Admin Lite Email
                 </label>

              <input
                 type="email"
              name="email"
               placeholder="adminlite@example.com"
                  required
                  class={[
                "w-full rounded-xl px-3 py-2.5 text-sm font-medium border focus:ring-2 focus:ring-indigo-500 outline-none transition",
                 @theme == "dark" && "bg-slate-950 border-slate-800 text-slate-200 placeholder:text-slate-600",
               @theme == "light" && "bg-slate-50 border-slate-200 text-slate-800 placeholder:text-slate-400"
               ]}
             />
            </div>

                   <div class="pt-2">
                 <button
            type="submit"
                 class="w-full sm:w-auto px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs transition shadow-lg shadow-indigo-600/20 active:scale-[0.98]"
             >
                  Generate Admin Lite Link
              </button>
               </div>
              </form>

              <!-- Generated Link Output Box -->
              <div :if={@generated_link} class="pt-4 border-t border-slate-700/30 space-y-2">
                <span class="text-xs font-semibold uppercase tracking-wider text-indigo-400">
                  Generated Link Ready
                </span>
                <div class={[
                  "flex items-center gap-2 p-2.5 rounded-xl border font-mono text-xs overflow-hidden",
                  @theme == "dark" && "bg-slate-950 border-slate-800 text-indigo-300",
                  @theme == "light" && "bg-indigo-50/50 border-indigo-200 text-indigo-700"
                ]}>
                  <input
                    type="text"
                    readonly
                    value={@generated_link}
                    class="bg-transparent flex-1 outline-none text-ellipsis"
                  />
                 <button
  type="button"
  phx-click="copy_link"
  phx-value-url={@generated_link}
  class={[
    "px-3 py-1.5 rounded-lg text-xs font-semibold transition shrink-0 flex items-center gap-1.5",
    @link_copied && "bg-emerald-600 text-white",
    !@link_copied && "bg-indigo-600 hover:bg-indigo-500 text-white"
  ]}
>
  <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3" />
  </svg>
  <%= if @link_copied, do: "Copied!", else: "Copy" %>
</button>
                </div>
              </div>
            </div>

           <!-- Enhanced Admin Activity Panel -->
<div class={[
  "p-6 rounded-2xl border transition-all space-y-4",
  @theme == "dark" && "bg-slate-900 border-slate-800 text-slate-100",
  @theme == "light" && "bg-white border-slate-200 text-slate-800 shadow-sm"
]}>
  <div class="flex items-center justify-between border-b pb-3 border-slate-700/30">
    <h3 class="text-sm font-bold tracking-tight flex items-center gap-2">
      <svg class="w-4 h-4 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>
      Generated Admin Invites (<%= length(@invites) %>)
    </h3>
  </div>

  <div class="space-y-3 text-xs overflow-y-auto max-h-[420px] pr-1">
    <div :for={invite <- @invites} class={[
      "rounded-xl border transition-all overflow-hidden",
      @theme == "dark" && "bg-slate-950/60 border-slate-800/80 hover:border-slate-700",
      @theme == "light" && "bg-slate-50 border-slate-200 hover:border-slate-300"
    ]}>
      <!-- Email & Status Header -->
      <div class="p-3 flex items-center justify-between gap-2 border-b border-slate-800/20">
        <div class="flex items-center gap-2 min-w-0">
          <div class="w-7 h-7 rounded-lg bg-indigo-500/10 text-indigo-400 font-bold flex items-center justify-center shrink-0 border border-indigo-500/20 text-[11px]">
            <%= String.first(invite.email) |> String.upcase() %>
          </div>
          <div class="truncate">
            <p class="font-bold text-xs truncate"><%= invite.email %></p>
            <p class="text-[10px] text-slate-400">
              Created <%= Calendar.strftime(invite.inserted_at, "%b %d, %Y at %H:%M") %>
            </p>
          </div>
        </div>

        <!-- Status Badges -->
        <div class="shrink-0 flex items-center gap-1.5">
          <%= if Map.get(invite, :suspended, false) do %>
            <span class="px-2 py-0.5 rounded-md text-[10px] font-semibold uppercase bg-amber-500/10 text-amber-400 border border-amber-500/20">
              Suspended
            </span>
          <% else %>
            <span class={[
              "px-2 py-0.5 rounded-md text-[10px] font-semibold uppercase border",
              invite.used && "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
              !invite.used && "bg-indigo-500/10 text-indigo-400 border-indigo-500/20"
            ]}>
              <%= if invite.used, do: "Used", else: "Active" %>
            </span>
          <% end %>
        </div>
      </div>

      <!-- Collapsible Dropdown for Token Details & Actions -->
      <details class="group">
        <summary class="px-3 py-2 text-[11px] font-semibold text-slate-400 hover:text-slate-200 cursor-pointer flex items-center justify-between select-none bg-slate-900/30">
          <span>Show Link & Controls</span>
          <svg class="w-3.5 h-3.5 transition-transform group-open:rotate-180 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </summary>

        <div class="p-3 pt-2 space-y-3 bg-slate-900/10 border-t border-slate-800/40">
          <!-- Token / Link Field -->
          <div class="space-y-1">
            <label class="text-[10px] uppercase font-bold text-slate-400 tracking-wider">Invite Link</label>
            <div class="flex items-center gap-1.5">
              <input
                type="text"
                readonly
                value={"#{HomeWeb.Endpoint.url()}/verification?token=#{invite.token}"}
                class="w-full bg-slate-950 border border-slate-800 rounded-lg px-2.5 py-1 text-[11px] font-mono text-indigo-300 outline-none truncate"
              />
              <button
  type="button"
  phx-click="copy_link"
  phx-value-url={"#{HomeWeb.Endpoint.url()}/verification?token=#{invite.token}"}
  class="px-2.5 py-1 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg text-[10px] font-semibold shrink-0 transition"
>
  Copy
</button>
            </div>
          </div>

          <!-- Quick Actions: Suspend & Fire -->
          <div class="flex items-center justify-end gap-2 pt-1 border-t border-slate-800/30">
            <button
              phx-click="toggle_suspend_invite"
              phx-value-id={invite.id}
              type="button"
              class="px-2.5 py-1 rounded-lg text-[10px] font-semibold bg-amber-500/10 hover:bg-amber-500/20 text-amber-400 border border-amber-500/30 transition flex items-center gap-1"
            >
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 9v6m4-6v6m7-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <%= if Map.get(invite, :suspended, false), do: "Unsuspend", else: "Suspend" %>
            </button>

            <button
              phx-click="revoke_invite"
              phx-value-id={invite.id}
              data-confirm="Are you sure you want to fire/revoke this invite link?"
              type="button"
              class="px-2.5 py-1 rounded-lg text-[10px] font-semibold bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/30 transition flex items-center gap-1"
            >
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
              Fire 🔥
            </button>
          </div>
        </div>
      </details>
    </div>
  </div>
</div>
          </div>
        </main>
      </div>
    </div>
    """
  end

  # Helper Component: Metric Card
  defp stat_card(assigns) do
    ~H"""
    <div class={[
      "p-4 rounded-2xl border transition-all",
      @theme == "dark" && "bg-slate-900 border-slate-800",
      @theme == "light" && "bg-white border-slate-200 shadow-sm"
    ]}>
      <p class="text-xs font-medium text-slate-400 uppercase tracking-wider"><%= @title %></p>
      <p class="text-2xl font-black mt-1 tracking-tight"><%= @value %></p>
    </div>
    """
  end

  # Shared Navigation Links Component
  defp nav_contents(assigns) do
    ~H"""
    <nav class="space-y-1">
      <.nav_item icon="dashboard" label="Overview" path={~p"/admin/dashboard"} theme={@theme} active={false} />
      <.nav_item icon="staff" label="Staff Operations" path={~p"/lite/dashboard"} theme={@theme} active={true} />
      <.nav_item icon="activity" label="Activity Logs" path={~p"/lite/dashboard"} theme={@theme} active={false} />
    </nav>
    """
  end

  # Helper Navigation Item Component
  defp nav_item(assigns) do
    ~H"""
    <.link
      navigate={@path}
      class={[
        "flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all",
        @active && @theme == "dark" && "bg-indigo-600/20 text-indigo-400 border border-indigo-500/30 shadow-sm",
        @active && @theme == "light" && "bg-indigo-50 text-indigo-600 border border-indigo-200 font-bold",
        !@active && @theme == "dark" && "text-slate-400 hover:text-slate-200 hover:bg-slate-800/50",
        !@active && @theme == "light" && "text-slate-600 hover:text-slate-900 hover:bg-slate-100"
      ]}
    >
      <%= case @icon do %>
        <% "dashboard" -> %>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
          </svg>
        <% "staff" -> %>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
        <% "activity" -> %>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
          </svg>
        <% _ -> %>
          <span class="w-2 h-2 rounded-full bg-current"></span>
      <% end %>
      <span><%= @label %></span>
    </.link>
    """
  end
end
