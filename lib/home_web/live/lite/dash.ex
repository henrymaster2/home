defmodule HomeWeb.Lite.DashboardLive do
  use HomeWeb, :live_view
  alias Home.Accounts

  @impl true
def mount(_params, _session, socket) do
  # Subscribe to verification requests for realtime updates
  if connected?(socket) do
    Accounts.subscribe_verification_requests()
  end

  # Fetch initial requests from DB
  verification_requests = Accounts.list_verification_requests()

  socket =
    socket
    |> assign(:theme, "dark")
    |> assign(:page_title, "Lite Dashboard")
    |> assign(:active_tab, "overview")
    |> assign(:landlords, verification_requests)
    |> assign(:show_add_modal, false)
    |> assign(:mobile_menu_open, false)
    |> assign(:generated_link, nil)
    |> assign(:form, to_form(%{
      "name" => "",
      "email" => "",
      "phone" => ""
    }))

  {:ok, socket}
end


@impl true
def handle_event("save_landlord", %{"landlord" => %{"email" => email}}, socket) do
  # Fetch user from current_scope instead of current_user
  admin_lite_user = socket.assigns.current_scope.user

  invite_params = %{
    email: email,
    token: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false),
    expires_at: DateTime.add(DateTime.utc_now(), 48, :hour),
    invite_type: "landlord",
    created_by_id: admin_lite_user.id
  }

  case Accounts.create_invite(invite_params) do
    {:ok, invite} ->
      invite_url = HomeWeb.Endpoint.url() <> ~p"/verification?token=#{invite.token}"

      {:noreply, assign(socket, generated_link: invite_url)}

    {:error, changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end


@impl true
def handle_info({:new_verification_request, new_request}, socket) do
  {:noreply,
   socket
   |> update(:landlords, fn landlords ->
     [new_request | landlords]
   end)
   |> put_flash(
     :info,
     "New verification request received from #{new_request.names}!"
   )}
end


@impl true
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
def handle_event("toggle_mobile_menu", _params, socket) do
  {:noreply,
   assign(
     socket,
     :mobile_menu_open,
     !socket.assigns.mobile_menu_open
   )}
end


@impl true
def handle_event("set_tab", %{"tab" => tab}, socket) do
  socket =
    socket
    |> assign(:active_tab, tab)
    |> assign(:mobile_menu_open, false)

  {:noreply, socket}
end


@impl true
def handle_event("open_add_modal", _params, socket) do
  {:noreply, assign(socket, :show_add_modal, true)}
end


@impl true
def handle_event("close_add_modal", _params, socket) do
  {:noreply, assign(socket, :show_add_modal, false)}
end


@impl true
def handle_event("validate", %{"landlord" => params}, socket) do
  {:noreply,
   assign(
     socket,
     :form,
     to_form(params, as: :landlord)
   )}
end


defp initials(nil), do: "??"

defp initials(name) do
  name
  |> String.split(" ", trim: true)
  |> Enum.map(&String.first/1)
  |> Enum.take(2)
  |> Enum.join()
  |> String.upcase()
end


@impl true
def handle_event("copy_detail", %{"type" => type, "val" => value}, socket) do
  socket =
    socket
    |> push_event("copy-to-clipboard", %{text: value})
    |> put_flash(:info, "Copied #{type}: #{value}")

  {:noreply, socket}
end


defp refresh_landlords(socket, landlords, name) do
  socket
  |> assign(:landlords, landlords)
  |> assign(:show_add_modal, false)
  |> assign(
    :form,
    to_form(%{
      "name" => "",
      "email" => "",
      "phone" => ""
    })
  )
  |> put_flash(
    :info,
    "Verification link generated for #{name}"
  )
end



  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="font-sans"
      id="lite-dashboard"
      phx-hook="HouseFinder"
      style={
        if @theme == "light",
          do: "font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; --bg: #f8fafc; --bg-card: #ffffff; --bg-card-hover: #f1f5f9; --accent-purple: #6d28d9; --accent-purple-light: #7c3aed; --accent-purple-glow: rgba(109, 40, 217, 0.12); --text-main: #0f172a; --text-muted: #64748b; --border: rgba(0, 0, 0, 0.08); --border-accent: rgba(109, 40, 217, 0.25); background-color: var(--bg); color: var(--text-main); min-height: 100vh; position: relative;",
          else: "font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; --bg: #090d16; --bg-card: rgba(15, 23, 42, 0.75); --bg-card-hover: rgba(30, 41, 59, 0.8); --accent-purple: #6d28d9; --accent-purple-light: #8b5cf6; --accent-purple-glow: rgba(109, 40, 217, 0.25); --text-main: #f8fafc; --text-muted: #94a3b8; --border: rgba(255, 255, 255, 0.08); --border-accent: rgba(139, 92, 246, 0.3); background-color: var(--bg); color: var(--text-main); min-height: 100vh; position: relative;"
      }
    >
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

      <div style="position: fixed; border-radius: 50%; filter: blur(120px); pointer-events: none; z-index: 0; width: 500px; height: 500px; top: -100px; left: -100px; background: rgba(30, 27, 75, 0.4);"></div>
      <div style="position: fixed; border-radius: 50%; filter: blur(120px); pointer-events: none; z-index: 0; width: 600px; height: 600px; bottom: -150px; right: -100px; background: rgba(88, 28, 135, 0.25);"></div>

      <div class="relative z-10 flex flex-col lg:flex-row min-h-screen">
        <header
          class="lg:hidden sticky top-0 z-40 px-4 py-3 flex items-center justify-between border-b border-[var(--border)]"
          style="background: var(--bg-card); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); border: 1px solid var(--border); box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.3);"
        >
          <div class="flex items-center gap-3">
            <button phx-click="toggle_mobile_menu" class="p-2 text-[var(--text-muted)] hover:text-[var(--text-main)] rounded-lg">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 6h16M4 12h16M4 18h16"/></svg>
            </button>
            <div class="font-semibold text-sm tracking-tight text-[var(--text-main)]">Lite Operations</div>
          </div>
          <button phx-click="toggle_theme" class="p-2 rounded-lg text-[var(--text-muted)] hover:text-[var(--text-main)]">
            <%= if @theme == "dark" do %>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>
            <% else %>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M21 12.8A9 9 0 1111.2 3a7 7 0 009.8 9.8z"/></svg>
            <% end %>
          </button>
        </header>

        <%= if @mobile_menu_open do %>
          <div class="lg:hidden fixed inset-0 bg-slate-950/80 backdrop-blur-sm z-40" phx-click="toggle_mobile_menu"></div>
        <% end %>

        <aside
          class={[
            "fixed lg:sticky top-0 left-0 z-50 lg:z-auto w-[280px] lg:w-64 p-5 flex flex-col justify-between shrink-0 h-screen border-r border-[var(--border)] transition-transform duration-300 ease-in-out",
            if(@mobile_menu_open, do: "translate-x-0", else: "-translate-x-full lg:translate-x-0")
          ]}
          style="background: var(--bg-card); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); border: 1px solid var(--border); box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.3);"
        >
          <div>
            <div class="flex items-center gap-3 pb-6 mb-6 border-b border-[var(--border)]">
              <div class="w-8 h-8 rounded-lg bg-[var(--accent-purple)] text-white font-bold text-sm flex items-center justify-center shadow-md">
                L
              </div>
              <div>
                <div class="font-semibold text-sm text-[var(--text-main)]">Lite Operations</div>
                <div class="text-xs text-[var(--text-muted)]">Enterprise Console</div>
              </div>
            </div>

            <nav class="space-y-1">
              <button
                phx-click="set_tab"
                phx-value-tab="overview"
                class="w-full flex items-center gap-3 px-3.5 py-2.5 text-xs font-medium hover:text-[var(--text-main)] hover:bg-white/5"
                style={
                  if @active_tab == "overview",
                    do: "color: #ffffff; background-color: var(--accent-purple); box-shadow: 0 4px 12px var(--accent-purple-glow); font-weight: 600; border-radius: 0.5rem; transition: all 0.2s ease;",
                    else: "color: var(--text-muted); border-radius: 0.5rem; transition: all 0.2s ease;"
                }
              >
                Overview
              </button>
              <button
                phx-click="set_tab"
                phx-value-tab="landlords"
                class="w-full flex items-center gap-3 px-3.5 py-2.5 text-xs font-medium hover:text-[var(--text-main)] hover:bg-white/5"
                style={
                  if @active_tab == "landlords",
                    do: "color: #ffffff; background-color: var(--accent-purple); box-shadow: 0 4px 12px var(--accent-purple-glow); font-weight: 600; border-radius: 0.5rem; transition: all 0.2s ease;",
                    else: "color: var(--text-muted); border-radius: 0.5rem; transition: all 0.2s ease;"
                }
              >
                Landlords
              </button>
              <button
                phx-click="set_tab"
                phx-value-tab="verifications"
                class="w-full flex items-center gap-3 px-3.5 py-2.5 text-xs font-medium hover:text-[var(--text-main)] hover:bg-white/5"
                style={
                  if @active_tab == "verifications",
                    do: "color: #ffffff; background-color: var(--accent-purple); box-shadow: 0 4px 12px var(--accent-purple-glow); font-weight: 600; border-radius: 0.5rem; transition: all 0.2s ease;",
                    else: "color: var(--text-muted); border-radius: 0.5rem; transition: all 0.2s ease;"
                }
              >
                Verifications
              </button>
              <button
                phx-click="set_tab"
                phx-value-tab="settings"
                class="w-full flex items-center gap-3 px-3.5 py-2.5 text-xs font-medium hover:text-[var(--text-main)] hover:bg-white/5"
                style={
                  if @active_tab == "settings",
                    do: "color: #ffffff; background-color: var(--accent-purple); box-shadow: 0 4px 12px var(--accent-purple-glow); font-weight: 600; border-radius: 0.5rem; transition: all 0.2s ease;",
                    else: "color: var(--text-muted); border-radius: 0.5rem; transition: all 0.2s ease;"
                }
              >
                Settings
              </button>
            </nav>
          </div>

          <div class="pt-6 space-y-3 border-t border-[var(--border)]">
            <button phx-click="toggle_theme" class="hidden lg:flex w-full items-center justify-between px-3.5 py-2.5 rounded-lg text-xs text-[var(--text-muted)] hover:text-[var(--text-main)] transition">
              <span>Appearance</span>
              <span class="text-[11px] uppercase tracking-wider font-semibold text-[var(--accent-purple-light)]">{@theme}</span>
            </button>

            <.link href={~p"/users/log_out"} method="delete" class="w-full block text-center py-2 rounded-lg text-xs font-medium text-rose-400 hover:text-rose-300 hover:bg-rose-500/10 transition">
              Log out
            </.link>
          </div>
        </aside>

        <main class="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl mx-auto w-full">
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
            <div>
              <h1 class="text-xl sm:text-2xl font-bold tracking-tight text-[var(--text-main)]">Dashboard</h1>
              <p class="text-xs sm:text-sm text-[var(--text-muted)] mt-1">Manage landlord verification requests and access controls.</p>
            </div>
            <button
              phx-click="open_add_modal"
              class="text-xs px-4 py-2.5 rounded-lg font-medium flex items-center justify-center gap-2 self-start sm:self-auto hover:bg-[var(--accent-purple-light)] hover:-translate-y-0.5"
              style="background-color: var(--accent-purple); color: #ffffff; box-shadow: 0 4px 14px var(--accent-purple-glow); transition: all 0.2s ease;"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>
              <span>Add Landlord</span>
            </button>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
            <div class="rounded-xl p-5" style="background: var(--bg-card); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); border: 1px solid var(--border); box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.3);">
              <div class="text-xs font-medium text-[var(--text-muted)]">Total Requests</div>
              <div class="text-2xl sm:text-3xl font-bold mt-2 text-[var(--text-main)]">{length(@landlords)}</div>
            </div>
            <div class="rounded-xl p-5" style="background: var(--bg-card); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); border: 1px solid var(--border); box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.3);">
              <div class="text-xs font-medium text-[var(--text-muted)]">Pending Verification</div>
              <div class="text-2xl sm:text-3xl font-bold mt-2 text-amber-400">
                {Enum.count(@landlords, &(Map.get(&1, :status) == "pending"))}
              </div>
            </div>
            <div class="rounded-xl p-5" style="background: var(--bg-card); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); border: 1px solid var(--border); box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.3);">
              <div class="text-xs font-medium text-[var(--text-muted)]">Verified Accounts</div>
              <div class="text-2xl sm:text-3xl font-bold mt-2 text-violet-400">
                {Enum.count(@landlords, &(Map.get(&1, :status) == "verified"))}
              </div>
            </div>
          </div>

          <!-- LANDLORD REQUESTS TABLE -->
          <div class="rounded-xl overflow-hidden border border-[var(--border)]" style="background: var(--bg-card); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); border: 1px solid var(--border); box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.3);">
            <div class="p-4 sm:p-5 border-b border-[var(--border)] flex items-center justify-between">
              <h2 class="text-sm font-semibold text-[var(--text-main)]">Landlord Requests</h2>
              <span class="text-xs text-[var(--text-muted)]">{length(@landlords)} total</span>
            </div>

            <div class="overflow-x-auto">
              <table class="w-full text-left text-xs min-w-[600px]">
                <thead>
                  <tr class="border-b border-[var(--border)] text-[11px] font-medium text-[var(--text-muted)] uppercase tracking-wider">
                    <th class="p-4">Landlord</th>
                    <th class="p-4">Contact Information</th>
                    <th class="p-4">Status</th>
                    <th class="p-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-[var(--border)]">
                  <%= for l <- @landlords do %>
                    <tr class="hover:bg-[var(--bg-card-hover)] transition">
                      <td class="p-4">
                        <div class="flex items-center gap-3">
                          <div class="w-8 h-8 rounded-full bg-violet-950/80 border border-violet-500/30 text-violet-300 font-semibold text-xs flex items-center justify-center shrink-0">
                            {initials(Map.get(l, :name))}
                          </div>
                          <span class="font-medium text-[var(--text-main)]">{Map.get(l, :name)}</span>
                        </div>
                      </td>
                      <td class="p-4">
                        <div class="text-[var(--text-main)]">{Map.get(l, :email)}</div>
                        <div class="text-[11px] text-[var(--text-muted)]">{Map.get(l, :phone)}</div>
                      </td>
                      <td class="p-4">
                        <%= if Map.get(l, :status) == "pending" do %>
                          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-amber-500/10 text-amber-300 border border-amber-500/20">
                            Pending
                          </span>
                        <% else %>
                          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-medium bg-violet-500/10 text-violet-300 border border-violet-500/20">
                            Verified
                          </span>
                        <% end %>
                      </td>
                      <td class="p-4 text-right">
                        <!-- DROPDOWN MENU -->
                        <details class="relative inline-block text-left">
                          <summary class="cursor-pointer list-none px-3 py-1.5 rounded-md bg-slate-900/60 border border-[var(--border)] text-[var(--text-muted)] hover:text-[var(--text-main)] hover:border-violet-500/40 transition text-[11px] font-medium inline-flex items-center gap-1.5">
                            <span>Copy Details</span>
                            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
                          </summary>

                          <div class="absolute right-0 mt-2 w-44 rounded-lg border border-[var(--border)] shadow-2xl z-30 py-1 text-left" style="background: var(--bg-card); backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px); border: 1px solid var(--border); box-shadow: 0 4px 20px -2px rgba(0, 0, 0, 0.3);">
                            <button
                              phx-click="copy_detail"
                              phx-value-type="Name"
                              phx-value-val={Map.get(l, :names)}
                              class="w-full px-3 py-2 text-[11px] hover:bg-violet-500/10 text-[var(--text-main)] flex items-center gap-2 transition"
                            >
                              <svg class="w-3.5 h-3.5 text-violet-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
                              <span>Copy Name</span>
                            </button>
                            <button
                              phx-click="copy_detail"
                              phx-value-type="Email"
                              phx-value-val={Map.get(l, :email)}
                              class="w-full px-3 py-2 text-[11px] hover:bg-violet-500/10 text-[var(--text-main)] flex items-center gap-2 transition"
                            >
                              <svg class="w-3.5 h-3.5 text-violet-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/></svg>
                              <span>Copy Email</span>
                            </button>
                            <button
                              phx-click="copy_detail"
                              phx-value-type="Phone"
                              phx-value-val={Map.get(l, :phone)}
                              class="w-full px-3 py-2 text-[11px] hover:bg-violet-500/10 text-[var(--text-main)] flex items-center gap-2 transition"
                            >
                              <svg class="w-3.5 h-3.5 text-violet-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"/></svg>
                              <span>Copy Phone</span>
                            </button>
                          </div>
                        </details>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
          <!-- END LANDLORD REQUESTS TABLE -->
        </main>
      </div>


     <%= if @show_add_modal do %>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/40 backdrop-blur-sm transition-all"
    phx-window-keydown="close_add_modal"
    phx-key="escape"
  >
    <div
      class="w-full max-w-lg rounded-3xl p-7 relative transition-all shadow-2xl"
      style="background: var(--bg-card); border: 1px solid var(--border); color: var(--text-main);"
      phx-click-away="close_add_modal"
    >
      <!-- Header -->
      <div class="flex items-start justify-between">
        <div class="flex items-center gap-3.5">
          <div
            class="w-11 h-11 rounded-2xl flex items-center justify-center shrink-0"
            style="background: rgba(147, 51, 234, 0.1); border: 1px solid var(--border); color: var(--accent-purple, #8b5cf6);"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
            </svg>
          </div>
          <div>
            <h3 class="text-base font-bold tracking-tight" style="color: var(--text-main);">Landlord Access Link</h3>
            <p class="text-xs font-normal mt-0.5" style="color: var(--text-muted);">
              <%= if @generated_link, do: "Link generated successfully. Copy and send to landlord.", else: "Create a secure, single-use invite link." %>
            </p>
          </div>
        </div>

        <button type="button" phx-click="close_add_modal" class="p-1.5 rounded-full hover:opacity-80 transition" style="color: var(--text-muted);">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <div class="my-5 border-t" style="border-color: var(--border);"></div>

      <%= if @generated_link do %>
        <!-- Result State: Link Output & Copy Button -->
        <div class="space-y-4">
          <label class="block text-[11px] font-bold tracking-wider uppercase" style="color: var(--text-muted);">
            Generated Invite Link
          </label>
          <div class="flex items-center gap-2">
            <input
              type="text"
              id="invite-link-input"
              readonly
              value={@generated_link}
              class="w-full px-4 py-3 rounded-2xl text-xs font-mono transition focus:outline-none"
              style="background: var(--bg-main, rgba(0,0,0,0.03)); border: 1px solid var(--border); color: var(--text-main);"
            />
            <button
              type="button"
              phx-click="copy_detail"
              phx-value-type="Invite link"
              phx-value-val={@generated_link}
              class="px-4 py-3 rounded-2xl text-xs font-semibold text-white shrink-0 transition active:scale-95"
              style="background-color: var(--accent-purple, #8b5cf6);"
            >
              Copy Link
            </button>
          </div>
          <div class="pt-3 flex justify-end">
            <button
              type="button"
              phx-click="close_add_modal"
              class="px-5 py-2.5 rounded-2xl text-xs font-semibold transition hover:opacity-80"
              style="border: 1px solid var(--border); color: var(--text-main);"
            >
              Done
            </button>
          </div>
        </div>
      <% else %>
        <!-- Input Form State -->
        <.form for={@form} phx-change="validate" phx-submit="save_landlord" class="space-y-6">
          <div>
            <label class="block text-[11px] font-bold tracking-wider uppercase mb-2" style="color: var(--text-muted);">
              Landlord Email Address
            </label>
            <input
              type="email"
              name="landlord[email]"
              value={@form[:email].value}
              required
              placeholder="landlord@example.com"
              class="w-full px-4 py-3 rounded-2xl text-sm font-medium transition focus:outline-none focus:ring-2 focus:ring-purple-500/20"
              style="background: var(--bg-main, rgba(0,0,0,0.03)); border: 1px solid var(--border); color: var(--text-main);"
            />
          </div>

          <div class="flex items-center gap-3 pt-1">
            <button
              type="submit"
              class="px-6 py-3 rounded-2xl text-xs font-semibold text-white transition-all duration-200 active:scale-95"
              style="background-color: var(--accent-purple, #8b5cf6); box-shadow: 0 4px 14px var(--accent-purple-glow, rgba(139, 92, 246, 0.3));"
            >
              Generate Landlord Link
            </button>
            <button
              type="button"
              phx-click="close_add_modal"
              class="px-5 py-3 rounded-2xl text-xs font-semibold transition hover:opacity-80"
              style="border: 1px solid var(--border); color: var(--text-main); background: transparent;"
            >
              Cancel
            </button>
          </div>
        </.form>
      <% end %>
    </div>
  </div>
<% end %>
    </div>
    """
  end
end
