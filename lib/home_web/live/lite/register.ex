defmodule HomeWeb.Lite.Register do
  use HomeWeb, :live_view
  alias Home.Accounts

  @impl true
  def mount(params, _session, socket) do
    token = params["token"]

    socket =
      socket
      |> assign(:theme, "dark")
      |> assign(:mobile_menu_open, false)
      |> assign(:request_submitted, false)
      |> assign(:submitted_details, nil)
      |> assign(:request_error, nil)
      |> assign(:role, nil)

    socket =
      if token do
        case Accounts.get_invite_by_token(token) do
          {:ok, invite} ->
            role = detect_role(invite)

            socket
            |> assign(:invite, invite)
            |> assign(:role, role)
            |> assign(:invite_status, :valid)

          {:error, :already_used, _invite} ->
            socket
            |> assign(:invite, nil)
            |> assign(:invite_status, :already_used)

          {:error, :not_found} ->
            socket
            |> assign(:invite, nil)
            |> assign(:invite_status, :invalid)
        end
      else
        socket
        |> assign(:invite, nil)
        |> assign(:invite_status, :none)
      end

    {:ok, socket}
  end

  # Helper function to detect role from the token invite record
  defp detect_role(invite) do
    role =
      Map.get(invite, :role) ||
        Map.get(invite, "role") ||
        Map.get(invite, :invite_type) ||
        Map.get(invite, "invite_type") ||
        "landlord"

    to_string(role) |> String.downcase()
  end

  # STAGE 1: Landlord submits request (Saved to DB for Admin approval)
  @impl true
  def handle_event("submit_verification_request", params, socket) do
    request_attrs = %{
      "names" => params["names"],
      "email" => params["email"],
      "phone" => params["phone"]
    }

    case Accounts.create_verification_request(request_attrs) do
      {:ok, _request} ->
        {:noreply,
         assign(socket,
           request_submitted: true,
           submitted_details: request_attrs,
           request_error: nil
         )}

      {:error, _changeset} ->
        {:noreply,
         assign(socket,
           request_error: "Could not submit request. Please check your details or try again."
         )}
    end
  end

  # STAGE 2: User completes registration via Admin Token link
  @impl true
  def handle_event("register", params, socket) do
    invite = socket.assigns.invite

    attrs = %{
      "names" => Map.get(invite, :names) || params["names"],
      "email" => invite.email,
      "phone" => Map.get(invite, :phone) || params["phone"],
      "id_number" => params["id_number"],
      "password" => params["password"],
      "password_confirmation" => params["password_confirmation"],
      "role" => socket.assigns.role || Map.get(invite, :invite_type) || "landlord"
    }

    case Accounts.register_user(attrs) do
      {:ok, _user} ->
        Accounts.mark_invite_as_used(invite)

        {:noreply,
         socket
         |> put_flash(:info, "Account created and verified successfully!")
         |> redirect(to: ~p"/home")}

      {:error, changeset} ->
        IO.inspect(changeset.errors, label: "REGISTRATION ERRORS")
        {:noreply, socket}
    end
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class={if(@theme == "light", do: "light", else: "")}>
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">

      <style>
        .sleek-page {
          --bg: #060913;
          --bg2: #0d1326;
          --grid: #0066ff;
          --accent: #0066ff;
          --accent2: #9d4edd;
          --text: #f0f6ff;
          --text-dim: #8292b0;
          --glass: rgba(13, 19, 38, 0.65);
          --glass-strong: rgba(20, 30, 58, 0.85);
          --border: rgba(0, 102, 255, 0.28);
          --shadow-accent: rgba(0, 102, 255, 0.3);
          font-family: 'Plus Jakarta Sans', system-ui, -apple-system, sans-serif;
          background: var(--bg);
          color: var(--text);
        }

        .light .sleek-page {
          --bg: #eef1f7;
          --bg2: #ffffff;
          --grid: #0066ff;
          --accent: #0066ff;
          --accent2: #ff2fb0;
          --text: #0b1220;
          --text-dim: #5b6472;
          --glass: rgba(255, 255, 255, 0.75);
          --glass-strong: rgba(255, 255, 255, 0.9);
          --border: rgba(0, 102, 255, 0.22);
          --shadow-accent: rgba(0, 102, 255, 0.2);
        }

        /* Floor animation grid */
        .floor-wrap {
          position: fixed;
          inset: 0;
          z-index: 0;
          overflow: hidden;
          background: radial-gradient(ellipse at 50% 20%, var(--bg2), var(--bg) 75%);
        }
        .floor {
          position: absolute;
          left: -50%;
          right: -50%;
          bottom: -10%;
          height: 70%;
          background-image:
            linear-gradient(var(--grid) 1px, transparent 1px),
            linear-gradient(90deg, var(--grid) 1px, transparent 1px);
          background-size: 55px 55px;
          opacity: 0.12;
          transform: perspective(500px) rotateX(62deg);
          transform-origin: bottom;
          animation: drift 6s linear infinite;
        }
        @keyframes drift {
          from { background-position: 0 0, 0 0; }
          to { background-position: 0 55px, 0 0; }
        }

        .glow-orb {
          position: absolute;
          width: 50vmax;
          height: 50vmax;
          border-radius: 50%;
          filter: blur(100px);
          opacity: 0.22;
          pointer-events: none;
        }
        .glow-orb.a { background: var(--accent); top: -20%; left: -10%; }
        .glow-orb.b { background: var(--accent2); bottom: -25%; right: -15%; }

        /* Glass Panel */
        .glass-panel {
          background: var(--glass);
          backdrop-filter: blur(20px) saturate(140%);
          -webkit-backdrop-filter: blur(20px) saturate(140%);
          border: 1px solid var(--border);
          box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.4), 0 0 20px var(--shadow-accent);
        }

        .blue-glow-text {
          color: var(--accent);
          text-shadow: 0 0 12px var(--shadow-accent);
        }

        .sleek-input {
          background: rgba(0, 0, 0, 0.2);
          border: 1px solid var(--border);
          color: var(--text);
          font-family: inherit;
          transition: all 0.2s ease;
        }
        .light .sleek-input {
          background: rgba(255, 255, 255, 0.85);
        }
        .sleek-input:focus {
          border-color: var(--accent);
          box-shadow: 0 0 14px var(--shadow-accent);
          outline: none;
        }
        .sleek-input[readonly] {
          opacity: 0.65;
          cursor: not-allowed;
        }

        .sleek-btn {
          background: var(--accent);
          color: #ffffff;
          box-shadow: 0 8px 24px -4px var(--shadow-accent);
          transition: all 0.25s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .sleek-btn:hover {
          transform: translateY(-2px);
          box-shadow: 0 12px 30px -4px var(--shadow-accent);
          filter: brightness(1.1);
        }
        .sleek-btn:active {
          transform: translateY(0);
        }
      </style>

      <div
        id="register"
        phx-hook="HouseFinder"
        class="sleek-page relative min-h-dvh w-full flex items-center justify-center px-4 py-8 sm:py-12 overflow-x-hidden selection:bg-[var(--accent)] selection:text-white"
      >
        <!-- Ambient Grid & Glowing Background -->
        <div class="floor-wrap">
          <div class="glow-orb a"></div>
          <div class="glow-orb b"></div>
          <div class="floor"></div>
        </div>

        <!-- Theme Toggle Button -->
        <button
          type="button"
          phx-click="toggle_theme"
          class="fixed top-4 right-4 z-30 glass-panel rounded-full w-11 h-11 flex items-center justify-center transition-transform hover:scale-110 active:scale-95"
          aria-label="Toggle theme"
        >
          <%= if @theme == "dark" do %>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--accent)" stroke-width="2">
              <circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>
            </svg>
          <% else %>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="var(--accent)">
              <path d="M21 12.8A9 9 0 1111.2 3a7 7 0 009.8 9.8z"/>
            </svg>
          <% end %>
        </button>

        <!-- Main Card Container -->
        <div class="relative z-10 w-full max-w-md my-auto">
          <!-- Header -->
          <div class="text-center mb-6 sm:mb-8">
            <div class="mx-auto mb-3.5 w-14 h-14 sm:w-16 sm:h-16 rounded-2xl glass-panel flex items-center justify-center shadow-lg transform hover:scale-105 transition-transform duration-300">
              <span class="text-2xl sm:text-3xl font-extrabold blue-glow-text tracking-tight">H</span>
            </div>

            <h1 class="text-2xl sm:text-3xl font-bold tracking-tight">
              Welcome to Home
            </h1>

            <p class="mt-2 text-xs sm:text-sm text-[var(--text-dim)] px-2 font-medium">
              <%= case @invite_status do %>
                <% :valid -> %>
                  Complete your verification to access your dashboard😊
                <% :already_used -> %>
                  This invite link has already been used.
                <% :invalid -> %>
                  Invalid or expired invite token.
                <% _ -> %>
                  Request landlord verification to get started.
              <% end %>
            </p>
          </div>

          <%= case @invite_status do %>
            <% :valid -> %>
              <!-- STEP 2: TOKEN DETECTED & VALID -> COMPLETION FORM -->
              <div class="glass-panel rounded-3xl p-6 sm:p-8">
                <!-- Welcome Card for Admin role -->
                <%= if @role == "admin" do %>
                  <div class="mb-5 p-3.5 rounded-2xl bg-[var(--accent)]/10 border border-[var(--accent)]/30 flex items-center gap-3">
                    <div class="w-8 h-8 rounded-xl glass-panel flex items-center justify-center text-sm font-bold text-[var(--accent)]">
                      👑
                    </div>
                    <div>
                      <h4 class="text-xs font-bold text-[var(--text)]">Welcome Landlord</h4>
                      <p class="text-[11px] text-[var(--text-dim)]">You are creating an account with Admin access.</p>
                    </div>
                  </div>
                <% end %>

                <div class="mb-6 border-b border-[var(--border)] pb-4">
                  <h2 class="text-base sm:text-lg font-bold blue-glow-text">
                    Complete <%= String.capitalize(@role || "admin") %> Registration
                  </h2>
                  <p class="text-xs text-[var(--text-dim)] mt-1">Provide your official ID and set up your password.</p>
                </div>

                <form phx-submit="register" class="space-y-4">
                  <!-- Name -->
                  <div>
                    <label class="block text-xs font-semibold mb-1.5 text-[var(--text-dim)]">Full Name</label>
                    <input
                      type="text"
                      name="names"
                      value={Map.get(@invite, :names, "")}
                      readonly={not is_nil(Map.get(@invite, :names))}
                      required
                      placeholder="Enter Full Name"
                      class="sleek-input w-full rounded-2xl px-4 py-3 text-xs sm:text-sm"
                    />
                  </div>

                  <!-- Email -->
                  <div>
                    <label class="block text-xs font-semibold mb-1.5 text-[var(--text-dim)]">Email Address</label>
                    <input
                      type="email"
                      name="email"
                      value={@invite.email}
                      readonly
                      class="sleek-input w-full rounded-2xl px-4 py-3 text-xs sm:text-sm"
                    />
                  </div>

                  <!-- Phone -->
                  <div>
                    <label class="block text-xs font-semibold mb-1.5 text-[var(--text-dim)]">Phone Number</label>
                    <input
                      type="tel"
                      name="phone"
                      value={Map.get(@invite, :phone, "")}
                      readonly={not is_nil(Map.get(@invite, :phone))}
                      required
                      placeholder="07XXXXXXXX"
                      class="sleek-input w-full rounded-2xl px-4 py-3 text-xs sm:text-sm"
                    />
                  </div>

                  <!-- ID Number -->
                  <div>
                    <label class="block text-xs font-semibold mb-1.5 text-[var(--text-dim)]">ID / Passport Number</label>
                    <input
                      type="text"
                      name="id_number"
                      placeholder="Enter National ID"
                      required
                      class="sleek-input w-full rounded-2xl px-4 py-3 text-xs sm:text-sm placeholder:text-[var(--text-dim)]/50"
                    />
                  </div>

                  <!-- Password -->
                  <div>
                    <label class="block text-xs font-semibold mb-1.5 text-[var(--text-dim)]">Password</label>
                    <input
                      type="password"
                      name="password"
                      placeholder="Create password"
                      required
                      class="sleek-input w-full rounded-2xl px-4 py-3 text-xs sm:text-sm placeholder:text-[var(--text-dim)]/50"
                    />
                  </div>

                  <!-- Confirm Password -->
                  <div>
                    <label class="block text-xs font-semibold mb-1.5 text-[var(--text-dim)]">Confirm Password</label>
                    <input
                      type="password"
                      name="password_confirmation"
                      placeholder="Confirm password"
                      required
                      class="sleek-input w-full rounded-2xl px-4 py-3 text-xs sm:text-sm placeholder:text-[var(--text-dim)]/50"
                    />
                  </div>

                  <button
                    type="submit"
                    class="sleek-btn w-full rounded-2xl py-3.5 text-xs sm:text-sm font-bold tracking-wide mt-2"
                  >
                    Verify & Access Dashboard
                  </button>
                </form>
              </div>

            <% :already_used -> %>
              <!-- TOKEN ALREADY USED STATE -->
              <div class="glass-panel rounded-3xl p-6 sm:p-8 text-center space-y-5">
                <div class="w-16 h-16 rounded-full glass-panel border border-amber-500/40 text-amber-400 flex items-center justify-center mx-auto shadow-lg bg-amber-500/10">
                  <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>
                </div>

                <div>
                  <span class="inline-block px-3 py-1 rounded-full text-xs font-semibold tracking-wide text-amber-400 border border-amber-500/30 bg-amber-500/10 uppercase mb-3">
                    Invite Expired
                  </span>
                  <h2 class="text-xl sm:text-2xl font-bold blue-glow-text">Link Already Redeemed</h2>
                  <p class="text-xs sm:text-sm text-[var(--text-dim)] mt-2 leading-relaxed">
                    This registration link has already been used to create an account. Please proceed to sign in.
                  </p>
                </div>

                <div class="pt-2">
                  <.link navigate={~p"/login"} class="sleek-btn inline-block text-center w-full rounded-2xl py-3.5 text-xs sm:text-sm font-bold tracking-wide">
                    Go to Sign In
                  </.link>
                </div>
              </div>

            <% :invalid -> %>
              <!-- INVALID TOKEN STATE -->
              <div class="glass-panel rounded-3xl p-6 sm:p-8 text-center space-y-5">
                <div class="w-16 h-16 rounded-full glass-panel border border-rose-500/40 text-rose-400 flex items-center justify-center mx-auto shadow-lg bg-rose-500/10">
                  <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </div>

                <div>
                  <span class="inline-block px-3 py-1 rounded-full text-xs font-semibold tracking-wide text-rose-400 border border-rose-500/30 bg-rose-500/10 uppercase mb-3">
                    Invalid Link
                  </span>
                  <h2 class="text-xl sm:text-2xl font-bold blue-glow-text">Token Not Found</h2>
                  <p class="text-xs sm:text-sm text-[var(--text-dim)] mt-2 leading-relaxed">
                    The registration link is invalid or expired. You can submit a new verification request.
                  </p>
                </div>

                <div class="pt-2">
                  <.link navigate={~p"/register"} class="sleek-btn inline-block text-center w-full rounded-2xl py-3.5 text-xs sm:text-sm font-bold tracking-wide">
                    Request Verification
                  </.link>
                </div>
              </div>

            <% :none -> %>
              <!-- STEP 1: STANDARD VERIFICATION REQUEST FORM OR SUBMITTED VIEW -->
              <%= if @request_submitted do %>
                <!-- STEP 1 SUCCESS: DETAILS SUBMITTED STATUS -->
                <div class="glass-panel rounded-3xl p-6 sm:p-8 text-center space-y-5">
                  <div class="w-16 h-16 rounded-full glass-panel border border-[var(--accent)] text-[var(--accent)] flex items-center justify-center mx-auto shadow-lg">
                    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
                    </svg>
                  </div>

                  <div>
                    <span class="inline-block px-3 py-1 rounded-full text-xs font-semibold tracking-wide text-[var(--accent)] border border-[var(--accent)]/30 bg-[var(--accent)]/10 uppercase mb-3">
                      Status: Pending Verification
                    </span>
                    <h2 class="text-xl sm:text-2xl font-bold blue-glow-text">Details Submitted</h2>
                    <p class="text-xs sm:text-sm text-[var(--text-dim)] mt-2 leading-relaxed">
                      Wait for approval to receive a link. Our administration team is reviewing your verification request.
                    </p>
                  </div>

                  <%= if @submitted_details do %>
                    <div class="glass-panel rounded-2xl p-4 text-left text-xs space-y-2.5 border-l-4 border-[var(--accent)]">
                      <div class="flex justify-between items-center border-b border-[var(--border)] pb-2">
                        <span class="text-[var(--text-dim)] font-medium">Full Name</span>
                        <span class="font-semibold text-[var(--text)]"><%= @submitted_details["names"] %></span>
                      </div>
                      <div class="flex justify-between items-center border-b border-[var(--border)] pb-2">
                        <span class="text-[var(--text-dim)] font-medium">Email</span>
                        <span class="font-semibold text-[var(--text)]"><%= @submitted_details["email"] %></span>
                      </div>
                      <div class="flex justify-between items-center">
                        <span class="text-[var(--text-dim)] font-medium">Phone</span>
                        <span class="font-semibold text-[var(--text)]"><%= @submitted_details["phone"] %></span>
                      </div>
                    </div>
                  <% end %>

                  <div class="pt-2 text-xs font-medium text-[var(--text-dim)] flex items-center justify-center gap-2">
                    <span class="w-2 h-2 rounded-full bg-[var(--accent)] animate-ping"></span>
                    <span>Verification link will be emailed upon approval</span>
                  </div>
                </div>

              <% else %>

                <!-- STEP 1: REQUEST VERIFICATION FORM -->
                <div class="glass-panel rounded-3xl p-6 sm:p-8">
                  <div class="mb-6 border-b border-[var(--border)] pb-4">
                    <h2 class="text-base sm:text-lg font-bold blue-glow-text">Request Verification</h2>
                    <p class="text-xs text-[var(--text-dim)] mt-1">Submit your details so our admin team can reach out and issue an invite token.</p>
                  </div>

                  <%= if @request_error do %>
                    <div class="mb-4 p-3.5 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-400 text-xs font-medium">
                      {@request_error}
                    </div>
                  <% end %>

                  <form phx-submit="submit_verification_request" class="space-y-4">
                    <!-- Full Name -->
                    <div>
                      <label class="block text-xs font-semibold mb-1.5 text-[var(--text-dim)]">Full Name</label>
                      <input
                        type="text"
                        name="names"
                        placeholder="John Doe"
                        required
                        class="sleek-input w-full rounded-2xl px-4 py-3 text-xs sm:text-sm placeholder:text-[var(--text-dim)]/50"
                      />
                    </div>

                    <!-- Email -->
                    <div>
                      <label class="block text-xs font-semibold mb-1.5 text-[var(--text-dim)]">Email Address</label>
                      <input
                        type="email"
                        name="email"
                        placeholder="landlord@example.com"
                        required
                        class="sleek-input w-full rounded-2xl px-4 py-3 text-xs sm:text-sm placeholder:text-[var(--text-dim)]/50"
                      />
                    </div>

                    <!-- Phone Number -->
                    <div>
                      <label class="block text-xs font-semibold mb-1.5 text-[var(--text-dim)]">Phone Number</label>
                      <input
                        type="tel"
                        name="phone"
                        placeholder="07XXXXXXXX"
                        required
                        class="sleek-input w-full rounded-2xl px-4 py-3 text-xs sm:text-sm placeholder:text-[var(--text-dim)]/50"
                      />
                    </div>

                    <button
                      type="submit"
                      class="sleek-btn w-full rounded-2xl py-3.5 text-xs sm:text-sm font-bold tracking-wide mt-2"
                    >
                      Submit Verification Request
                    </button>
                  </form>
                </div>
              <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
