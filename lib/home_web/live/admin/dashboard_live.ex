defmodule HomeWeb.Admin.DashboardLive do
  use HomeWeb, :live_view
   alias Home.Accounts
  @impl true
  def mount(_params, session, socket) do

    current_admin =
    case Accounts.get_user_by_session_token(session["user_token"]) do
      {user, _inserted_at} -> user
      nil -> nil
    end
    if current_admin && current_admin.role == "admin" do
    {:ok,
     socket
     |> assign(:page_title, "admindash")
     |> assign(:current_admin, current_admin)
     |> assign(:sidebar_open, false)
     |> assign(:pending_expanded, false)
     |> assign(:theme, "dark")
     |> assign(:balance, "KES 142,500.00")
     |> assign(:system_balance, "KES 142.5k")
     |> assign(:total_revenue, "KES 88.4k")
     |> assign(:pending_reviews, 112)
     |> assign(:total_reviews, 145)
     |> assign(:new_threads, 14)
     |> assign(:flagged_threads, 2)}
     else
    {:ok,
     socket
     |> put_flash(:error, "You are not authorized to access this page.")
     |> redirect(to: ~p"/users/log-in")}
     end
end
  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  def handle_event("toggle_pending", _, socket) do
    {:noreply, update(socket, :pending_expanded, &(!&1))}
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
   |> push_event("set_global_theme", %{theme: new_theme})}
end

@impl true
def handle_event("restore_theme", %{"theme" => theme}, socket)
    when theme in ["dark", "light"] do
  {:noreply, assign(socket, :theme, theme)}
end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="admin-dashboard-root" phx-hook="HouseFinder" class={[
      "min-h-screen relative overflow-x-hidden transition-colors duration-500 font-sans",
      @theme == "dark" && "dark bg-[#0a0f1e] text-slate-200",
      @theme == "light" && "bg-gray-50 text-gray-800"
    ]}>
      <%# Ambient Glow Background %>
      <div class="fixed inset-0 pointer-events-none z-0 transition-opacity duration-500">
        <div class={[
          "absolute top-[-10%] left-[-10%] w-[600px] h-[600px] rounded-full blur-[120px]",
          @theme == "dark" && "bg-blue-900/20",
          @theme == "light" && "bg-blue-200/40"
        ]}></div>
        <div class={[
          "absolute top-[20%] right-[-5%] w-[500px] h-[500px] rounded-full blur-[100px]",
          @theme == "dark" && "bg-blue-800/15",
          @theme == "light" && "bg-blue-100/40"
        ]}></div>
        <div class={[
          "absolute bottom-[-10%] left-[30%] w-[700px] h-[700px] rounded-full blur-[140px]",
          @theme == "dark" && "bg-indigo-900/20",
          @theme == "light" && "bg-indigo-100/40"
        ]}></div>
      </div>

      <%# Mobile Header %>
      <div class={[
        "lg:hidden flex items-center justify-between p-4 sticky top-0 z-40 backdrop-blur-md border-b transition-colors duration-500",
        @theme == "dark" && "bg-[#0d1321]/80 border-slate-800/50",
        @theme == "light" && "bg-white/80 border-gray-200/50"
      ]}>
        <div class="flex items-center gap-3">
          <div class="w-8 h-8 rounded-full bg-linear-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-sm font-bold text-white">
            H
          </div>
          <div>
              <p class={["text-xs", @theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}>Welcome</p>
                <p class={["text-sm font-semibold", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}>
           <%= if @current_admin, do: @current_admin.names, else: "Admin" %>
               </p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <button
            phx-click="toggle_theme"
            class={[
              "p-2 rounded-lg transition-colors cursor-pointer",
              @theme == "dark" && "bg-slate-800/50 hover:bg-slate-700/50 text-slate-300",
              @theme == "light" && "bg-gray-100 hover:bg-gray-200 text-gray-600"
            ]}
          >
            <%= if @theme == "dark" do %>
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
            <% else %>
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/></svg>
            <% end %>
          </button>
          <button
            phx-click="toggle_sidebar"
            class={[
              "p-2 rounded-lg transition-colors cursor-pointer",
              @theme == "dark" && "bg-slate-800/50 hover:bg-slate-700/50 text-slate-300",
              @theme == "light" && "bg-gray-100 hover:bg-gray-200 text-gray-600"
            ]}
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
          </button>
        </div>
      </div>

      <div class="flex relative z-10">
        <%# Sidebar %>
        <aside class={[
          "fixed lg:sticky top-0 left-0 z-30 h-screen w-64 backdrop-blur-xl border-r transition-all duration-300 overflow-y-auto",
          @theme == "dark" && "bg-[#0d1321]/90 border-slate-800/50",
          @theme == "light" && "bg-white/90 border-gray-200/50",
          @sidebar_open && "translate-x-0",
          !@sidebar_open && "-translate-x-full lg:translate-x-0"
        ]}>
          <div class="p-6">
            <div class="hidden lg:flex items-center justify-between mb-8">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-full bg-linear-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-lg font-bold text-white shadow-lg shadow-blue-500/20">
                  H
                </div>
                <div>
                  <p class={["text-xs", @theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}>Welcome</p>
                <p class={["text-sm font-semibold", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}>
           <%= if @current_admin, do: @current_admin.names, else: "Admin" %>
               </p>
                </div>
              </div>
              <button
                phx-click="toggle_theme"
                class={[
                  "p-2 rounded-lg transition-colors cursor-pointer",
                  @theme == "dark" && "bg-slate-800/50 hover:bg-slate-700/50 text-slate-300",
                  @theme == "light" && "bg-gray-100 hover:bg-gray-200 text-gray-600"
                ]}
                title="Toggle theme"
              >
                <%= if @theme == "dark" do %>
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                <% else %>
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/></svg>
                <% end %>
              </button>
            </div>

            <nav class="space-y-1">
              <.nav_item icon="dashboard" label="Dashboard" active={true} theme={@theme} />

              <div class="pt-4 pb-2">
                <p class={["px-3 text-xs font-medium uppercase tracking-wider", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}>Financials</p>
              </div>
              <.nav_item icon="ledger" label="Ledger" theme={@theme} />
              <.nav_item icon="transaction" label="Transaction view" indent theme={@theme} />

              <div class="pt-4 pb-2">
                <p class={["px-3 text-xs font-medium uppercase tracking-wider", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}>Messaging</p>
              </div>
              <.nav_item icon="chat" label="Tenant Chats" theme={@theme} />
              <.nav_item icon="oversight" label="Oversight" theme={@theme} />

              <div class="pt-4 pb-2">
                <p class={["px-3 text-xs font-medium uppercase tracking-wider", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}>Admin Elites</p>
              </div>
              <.nav_item icon="activity" label="Activity" path={~p"/admin/lite"} theme={@theme} />
              <.nav_item icon="activity" label="staff" path={~p"/staff"} theme={@theme} />

              <div class="pt-4 pb-2">
                <p class={["px-3 text-xs font-medium uppercase tracking-wider", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}>Management</p>
              </div>
              <.nav_item icon="landlord" label="Verified Landlords" theme={@theme} />
              <.nav_item icon="report" label="Reports" theme={@theme} />
            </nav>
             <div class="pt-4 pb-2">
                <p class={["px-3 text-xs font-medium uppercase tracking-wider", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}>Activity</p>
              </div>
              <.link
                href={~p"/users/log_out"}
                 method="delete"
                class="block w-full text-center rounded-xl bg-red-500 px-4 py-2 text-white hover:bg-red-600 font-medium transition"
                    >
                Log out
               </.link>
          </div>
        </aside>

        <%# Overlay for mobile sidebar %>
        <div :if={@sidebar_open} phx-click="toggle_sidebar" class={[
          "fixed inset-0 z-20 lg:hidden backdrop-blur-sm transition-colors",
          @theme == "dark" && "bg-black/50",
          @theme == "light" && "bg-gray-900/20"
        ]}></div>

        <%# Main Content %>
        <main class="flex-1 p-4 lg:p-8 max-w-1600px">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
            <h1 class={["text-2xl lg:text-3xl font-bold tracking-tight", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}>
              DASHBOARD OVERVIEW
            </h1>
            <div class={[
              "inline-flex items-center gap-2 px-4 py-2 rounded-full backdrop-blur-sm border transition-colors",
              @theme == "dark" && "bg-slate-800/50 border-slate-700/50 text-slate-300",
              @theme == "light" && "bg-white border-gray-200 shadow-sm text-gray-600"
            ]}>
              <span class="relative flex h-2 w-2">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
              <span class="text-sm">Live balance:</span>
              <span class={["text-sm font-bold", @theme == "dark" && "text-emerald-400", @theme == "light" && "text-emerald-600"]}><%= @balance %></span>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4 mb-6">
            <.stat_card
              title="System Balance"
              value={@system_balance}
              filter="Monthly"
              trend="+15.5%"
              trend_up={true}
              chart_color="emerald"
              theme={@theme}
            />
            <.stat_card
              title="Total Revenue"
              value={@total_revenue}
              filter="Monthly"
              trend="+8.2%"
              trend_up={true}
              chart_color="blue"
              theme={@theme}
            />
            <.stat_card
              title="Pending Reviews"
              value={"#{@pending_reviews} / #{@total_reviews}"}
              subtitle="77.2%"
              filter="Monthly"
              expandable={true}
              expanded={@pending_expanded}
              theme={@theme}
            />
          </div>

          <div class="grid grid-cols-1 xl:grid-cols-2 gap-6 mb-6">
            <.glass_card title="VERIFICATION PIPELINE" class="xl:col-span-1" theme={@theme}>
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <.pipeline_column title="Pending" count={18} color="amber" theme={@theme}>
                  <.pipeline_card name="Jane Doe" type="National ID" theme={@theme} />
                  <.pipeline_card name="Jane Doe" type="National ID" theme={@theme} />
                </.pipeline_column>
                <.pipeline_column title="Under Review" count={9} color="blue" theme={@theme}>
                  <.pipeline_card name="Jane Doe" type="National ID" theme={@theme} />
                </.pipeline_column>
                <.pipeline_column title="Info Requested" count={4} color="purple" theme={@theme}>
                  <div class={["text-center py-8 text-sm", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}>
                    Awaiting response
                  </div>
                </.pipeline_column>
              </div>
            </.glass_card>

            <.glass_card title="RECENT TRANSACTIONS" class="xl:col-span-1" theme={@theme}>
              <div class="space-y-3">
                <.transaction_row name="John P." method="M-Pesa STK" time="13:45" amount="KES 5,000" status="Paid" theme={@theme} />
                <.transaction_row name="John P." method="M-Pesa STK" time="13:43" amount="KES 5,000" status="Paid" theme={@theme} />
                <.transaction_row name="John P." method="M-Pesa STK" time="13:40" amount="KES 5,000" status="Paid" theme={@theme} />
                <.transaction_row name="John P." method="M-Pesa STK" time="13:38" amount="KES 5,000" status="Pending" theme={@theme} />
              </div>
            </.glass_card>
          </div>

          <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
            <.glass_card title="STAFF ACTIVITY" theme={@theme}>
              <div class="flex items-center justify-between mb-4">
                <p class={["text-sm", @theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}>Admin Elites backlog, recently active</p>
                <span class={["text-xs", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}>Recently active</span>
              </div>
              <div class={[
                "flex items-center gap-3 p-3 rounded-xl border transition-colors",
                @theme == "dark" && "bg-slate-800/30 border-slate-700/30",
                @theme == "light" && "bg-gray-50 border-gray-200"
              ]}>
                <div class="w-10 h-10 rounded-full bg-linear-to-br from-orange-400 to-red-500 flex items-center justify-center text-sm font-bold text-white">
                  A
                </div>
                <div class="flex-1">
                  <p class={["text-sm font-medium", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}>Admin Elites</p>
                  <p class={["text-xs", @theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}>Processed 24 verifications today</p>
                </div>
                <span class={["text-xs", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}>1 hour ago</span>
              </div>
            </.glass_card>

            <.glass_card title="MESSAGING OVERSIGHT" theme={@theme}>
              <div class="grid grid-cols-2 gap-4">
                <div class={[
                  "p-4 rounded-xl border text-center transition-colors",
                  @theme == "dark" && "bg-slate-800/30 border-slate-700/30",
                  @theme == "light" && "bg-gray-50 border-gray-200"
                ]}>
                  <p class={["text-xs mb-1", @theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}>New Threads</p>
                  <p class={["text-3xl font-bold", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}><%= @new_threads %></p>
                </div>
                <div class={[
                  "p-4 rounded-xl border text-center transition-colors",
                  @theme == "dark" && "bg-red-900/20 border-red-800/30",
                  @theme == "light" && "bg-red-50 border-red-200"
                ]}>
                  <p class={["text-xs mb-1", @theme == "dark" && "text-red-300", @theme == "light" && "text-red-600"]}>Flagged (Red)</p>
                  <p class={["text-3xl font-bold", @theme == "dark" && "text-red-400", @theme == "light" && "text-red-600"]}><%= @flagged_threads %></p>
                </div>
              </div>
            </.glass_card>
          </div>
        </main>
      </div>
    </div>
    """
  end

  # --- Functional Components ---

  defp nav_item(assigns) do
    assigns =
      assigns
      |> Map.put_new(:active, false)
      |> Map.put_new(:indent, false)
      |> Map.put_new(:path, "#")

    ~H"""
    <.link navigate={@path} class={[
    "flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-all duration-200 group",
    @active && @theme == "light" && "bg-blue-50 text-blue-600 border border-blue-200",
    !@active && @theme == "light" && "text-gray-600 hover:text-gray-900 hover:bg-gray-100",
    @active && @theme == "dark" && "bg-blue-600/20 text-blue-300 border border-blue-500/30",
    !@active && @theme == "dark" && "text-slate-400 hover:text-slate-200 hover:bg-slate-800/50",
    @indent && "ml-4"
     ]}>
    <.nav_icon name={@icon} active={@active} theme={@theme} />
    <span class="font-medium"><%= @label %></span>
    <%= if @active do %>
      <div class="ml-auto w-1.5 h-1.5 rounded-full bg-blue-500 shadow-[0_0_8px_rgba(96,165,250,0.6)]"></div>
    <% end %>
     </.link>
    """
  end

  defp nav_icon(assigns) do
    assigns = Map.put_new(assigns, :active, false)

    ~H"""
    <%= case @name do %>
      <% "dashboard" -> %>
        <svg class={["w-4 h-4", @active && "text-blue-500", !@active && @theme == "dark" && "text-slate-500 group-hover:text-slate-300", !@active && @theme == "light" && "text-gray-400 group-hover:text-gray-600"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>
      <% "ledger" -> %>
        <svg class={["w-4 h-4", @active && "text-blue-500", !@active && @theme == "dark" && "text-slate-500 group-hover:text-slate-300", !@active && @theme == "light" && "text-gray-400 group-hover:text-gray-600"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"/></svg>
      <% "transaction" -> %>
        <svg class={["w-4 h-4", @active && "text-blue-500", !@active && @theme == "dark" && "text-slate-500 group-hover:text-slate-300", !@active && @theme == "light" && "text-gray-400 group-hover:text-gray-600"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/></svg>
      <% "chat" -> %>
        <svg class={["w-4 h-4", @active && "text-blue-500", !@active && @theme == "dark" && "text-slate-500 group-hover:text-slate-300", !@active && @theme == "light" && "text-gray-400 group-hover:text-gray-600"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/></svg>
      <% "oversight" -> %>
        <svg class={["w-4 h-4", @active && "text-blue-500", !@active && @theme == "dark" && "text-slate-500 group-hover:text-slate-300", !@active && @theme == "light" && "text-gray-400 group-hover:text-gray-600"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/></svg>
      <% "staff" -> %>
        <svg class={["w-4 h-4", @active && "text-blue-500", !@active && @theme == "dark" && "text-slate-500 group-hover:text-slate-300", !@active && @theme == "light" && "text-gray-400 group-hover:text-gray-600"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
      <% "activity" -> %>
        <svg class={["w-4 h-4", @active && "text-blue-500", !@active && @theme == "dark" && "text-slate-500 group-hover:text-slate-300", !@active && @theme == "light" && "text-gray-400 group-hover:text-gray-600"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/></svg>
      <% "landlord" -> %>
        <svg class={["w-4 h-4", @active && "text-blue-500", !@active && @theme == "dark" && "text-slate-500 group-hover:text-slate-300", !@active && @theme == "light" && "text-gray-400 group-hover:text-gray-600"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
      <% "report" -> %>
        <svg class={["w-4 h-4", @active && "text-blue-500", !@active && @theme == "dark" && "text-slate-500 group-hover:text-slate-300", !@active && @theme == "light" && "text-gray-400 group-hover:text-gray-600"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/></svg>
      <% _ -> %>
        <svg class={["w-4 h-4", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 12h.01M12 12h.01M19 12h.01M6 12a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0zm7 0a1 1 0 11-2 0 1 1 0 012 0z"/></svg>
    <% end %>
    """
  end

  defp glass_card(assigns) do
    assigns = Map.put_new(assigns, :class, "")

    ~H"""
    <div class={[
      "rounded-2xl border backdrop-blur-md p-5 transition-colors duration-500",
      @theme == "dark" && "bg-slate-900/40 border-slate-700/40 shadow-xl shadow-black/20",
      @theme == "light" && "bg-white/70 border-gray-200/60 shadow-lg shadow-gray-200/30",
      @class
    ]}>
      <div class="flex items-center justify-between mb-5">
        <h2 class={["text-sm font-bold tracking-wider", @theme == "dark" && "text-slate-300", @theme == "light" && "text-gray-600"]}><%= @title %></h2>
        <button class={["transition-colors cursor-pointer", @theme == "dark" && "text-slate-500 hover:text-slate-300", @theme == "light" && "text-gray-400 hover:text-gray-600"]}>
          <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path d="M10 6a2 2 0 110-4 2 2 0 010 4zM10 12a2 2 0 110-4 2 2 0 010 4zM10 18a2 2 0 110-4 2 2 0 010 4z"/></svg>
        </button>
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <div class={[
      "rounded-2xl border backdrop-blur-md p-5 transition-all duration-300 group",
      @theme == "dark" && "bg-slate-900/40 border-slate-700/40 shadow-xl shadow-black/20 hover:border-slate-600/50",
      @theme == "light" && "bg-white/70 border-gray-200/60 shadow-lg shadow-gray-200/30 hover:border-gray-300"
    ]}>
      <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-2">
          <h3 class={["text-sm font-medium", @theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}><%= @title %></h3>
          <%= if assigns[:filter] do %>
            <span class={[
              "text-[10px] px-2 py-0.5 rounded-full border flex items-center gap-1",
              @theme == "dark" && "bg-slate-800 text-slate-400 border-slate-700/50",
              @theme == "light" && "bg-gray-100 text-gray-500 border-gray-200"
            ]}>
              <%= @filter %>
              <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            </span>
          <% end %>
        </div>
        <%= if assigns[:trend] do %>
          <span class={[
            "text-xs font-medium flex items-center gap-1",
            @trend_up && @theme == "dark" && "text-emerald-400",
            @trend_up && @theme == "light" && "text-emerald-600",
            !@trend_up && @theme == "dark" && "text-red-400",
            !@trend_up && @theme == "light" && "text-red-600"
          ]}>
            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <%= if @trend_up do %>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/>
              <% else %>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6"/>
              <% end %>
            </svg>
            <%= @trend %>
          </span>
        <% end %>
      </div>

      <div class="flex items-end justify-between">
        <div>
          <p class={["text-2xl lg:text-3xl font-bold tracking-tight", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}><%= @value %></p>
          <%= if assigns[:subtitle] do %>
            <p class={["text-sm mt-1", @theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}><%= @subtitle %></p>
          <% end %>
        </div>

        <%= if assigns[:chart_color] do %>
          <div class="w-24 h-10 opacity-60 group-hover:opacity-100 transition-opacity">
            <svg viewBox="0 0 100 40" class="w-full h-full" preserveAspectRatio="none">
              <defs>
                <linearGradient id={"grad-#{@chart_color}"} x1="0%" y1="0%" x2="0%" y2="100%">
                  <stop offset="0%" stop-color={if @chart_color == "emerald", do: "#34d399", else: "#60a5fa"} stop-opacity="0.3"/>
                  <stop offset="100%" stop-color={if @chart_color == "emerald", do: "#34d399", else: "#60a5fa"} stop-opacity="0"/>
                </linearGradient>
              </defs>
              <path d="M0,35 Q10,30 20,32 T40,25 T60,28 T80,15 T100,20 L100,40 L0,40 Z" fill={"url(#grad-#{@chart_color})"}/>
              <path d="M0,35 Q10,30 20,32 T40,25 T60,28 T80,15 T100,20" fill="none" stroke={if @chart_color == "emerald", do: "#34d399", else: "#60a5fa"} stroke-width="2" stroke-linecap="round"/>
            </svg>
          </div>
        <% end %>

        <%= if assigns[:expandable] do %>
          <button phx-click="toggle_pending" class={[
            "p-1.5 rounded-lg transition-colors cursor-pointer",
            @theme == "dark" && "hover:bg-slate-800/50 text-slate-400",
            @theme == "light" && "hover:bg-gray-100 text-gray-400"
          ]}>
            <svg class={["w-5 h-5 transition-transform duration-300", @expanded && "rotate-180"]} fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
          </button>
        <% end %>
      </div>

      <%= if assigns[:expandable] && @expanded do %>
        <div class={["mt-4 pt-4 border-t space-y-2 animate-fade-in", @theme == "dark" && "border-slate-700/30", @theme == "light" && "border-gray-200"]}>
          <div class="flex items-center justify-between text-sm">
            <span class={[@theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}>ID Uploads</span>
            <span class={["font-medium", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}>45</span>
          </div>
          <div class="flex items-center justify-between text-sm">
            <span class={[@theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}>Bank Statements</span>
            <span class={["font-medium", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}>38</span>
          </div>
          <div class="flex items-center justify-between text-sm">
            <span class={[@theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}>Address Verifications</span>
            <span class={["font-medium", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}>29</span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp pipeline_column(assigns) do
    ~H"""
    <div class={[
      "rounded-xl border p-3 transition-colors",
      @theme == "dark" && "bg-slate-800/30 border-slate-700/30",
      @theme == "light" && "bg-gray-50/50 border-gray-200/60"
    ]}>
      <div class="flex items-center justify-between mb-3">
        <h3 class={["text-xs font-semibold uppercase tracking-wider", @theme == "dark" && "text-slate-400", @theme == "light" && "text-gray-500"]}><%= @title %></h3>
        <span class={[
          "text-xs font-bold px-2 py-0.5 rounded-full",
          @color == "amber" && @theme == "dark" && "bg-amber-500/20 text-amber-300",
          @color == "amber" && @theme == "light" && "bg-amber-100 text-amber-700",
          @color == "blue" && @theme == "dark" && "bg-blue-500/20 text-blue-300",
          @color == "blue" && @theme == "light" && "bg-blue-100 text-blue-700",
          @color == "purple" && @theme == "dark" && "bg-purple-500/20 text-purple-300",
          @color == "purple" && @theme == "light" && "bg-purple-100 text-purple-700"
        ]}><%= @count %></span>
      </div>
      <div class="space-y-2">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp pipeline_card(assigns) do
    ~H"""
    <div class={[
      "p-3 rounded-lg border transition-all group",
      @theme == "dark" && "bg-slate-800/50 border-slate-700/40 hover:border-slate-600/60",
      @theme == "light" && "bg-white border-gray-200 shadow-sm hover:border-gray-300"
    ]}>
      <div class="flex items-start justify-between mb-2">
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-full bg-linear-to-br from-pink-400 to-rose-500 flex items-center justify-center text-xs font-bold text-white">
            <%= String.first(@name) %>
          </div>
          <div>
            <p class={["text-sm font-medium", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}><%= @name %></p>
            <p class={["text-xs", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}><%= @type %></p>
          </div>
        </div>
        <button class={["cursor-pointer", @theme == "dark" && "text-slate-600 hover:text-slate-300", @theme == "light" && "text-gray-300 hover:text-gray-500"]}>
          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path d="M10 6a2 2 0 110-4 2 2 0 010 4zM10 12a2 2 0 110-4 2 2 0 010 4zM10 18a2 2 0 110-4 2 2 0 010 4z"/></svg>
        </button>
      </div>
      <div class="flex gap-2">
        <button class={[
          "flex-1 px-3 py-1.5 text-xs font-medium rounded-md border transition-colors cursor-pointer",
          @theme == "dark" && "bg-blue-600/20 text-blue-300 border-blue-500/30 hover:bg-blue-600/30",
          @theme == "light" && "bg-blue-50 text-blue-600 border-blue-200 hover:bg-blue-100"
        ]}>Review</button>
        <button class={[
          "flex-1 px-3 py-1.5 text-xs font-medium rounded-md border transition-colors cursor-pointer",
          @theme == "dark" && "bg-slate-700/50 text-slate-300 border-slate-600/30 hover:bg-slate-700/70",
          @theme == "light" && "bg-gray-100 text-gray-600 border-gray-200 hover:bg-gray-200"
        ]}>Details</button>
      </div>
    </div>
    """
  end

  defp transaction_row(assigns) do
    ~H"""
    <div class={[
      "flex items-center gap-3 p-3 rounded-lg border transition-colors",
      @theme == "dark" && "bg-slate-800/20 border-slate-700/20 hover:bg-slate-800/40",
      @theme == "light" && "bg-gray-50/50 border-gray-200/60 hover:bg-gray-100/50"
    ]}>
      <div class={[
        "w-8 h-8 rounded-full flex items-center justify-center",
        @theme == "dark" && "bg-slate-700/50 text-slate-400",
        @theme == "light" && "bg-gray-100 text-gray-400"
      ]}>
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
      </div>
      <div class="flex-1 min-w-0">
        <p class={["text-sm font-medium truncate", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}><%= @name %></p>
        <p class={["text-xs", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}><%= @method %></p>
      </div>
      <div class="text-right">
        <p class={["text-sm font-medium", @theme == "dark" && "text-white", @theme == "light" && "text-gray-900"]}><%= @amount %></p>
        <div class="flex items-center justify-end gap-2 mt-0.5">
          <span class={["text-xs", @theme == "dark" && "text-slate-500", @theme == "light" && "text-gray-400"]}><%= @time %></span>
          <span class={[
            "text-[10px] px-1.5 py-0.5 rounded-full font-medium",
            @status == "Paid" && @theme == "dark" && "bg-emerald-500/20 text-emerald-400",
            @status == "Paid" && @theme == "light" && "bg-emerald-100 text-emerald-700",
            @status != "Paid" && @theme == "dark" && "bg-amber-500/20 text-amber-400",
            @status != "Paid" && @theme == "light" && "bg-amber-100 text-amber-700"
          ]}><%= @status %></span>
        </div>
      </div>
    </div>
    """
  end
end
