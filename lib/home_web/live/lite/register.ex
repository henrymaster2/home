defmodule HomeWeb.Lite.Register do
  use HomeWeb, :live_view
  alias Home.Accounts
  alias Home.Accounts.AdminLiteInvite

  @impl true
  def mount(params, _session, socket) do
    token = params["token"]

    socket =
      socket
      |> assign(:theme, "dark")
      |> assign(:step, 1)
      |> assign(:mobile_steps_open, false)
      |> assign(:request_submitted, false)
      |> assign(:submitted_details, nil)
      |> assign(:request_error, nil)
      |> assign(:registration_error, nil)
      |> assign(:role, nil)
      |> assign(:invite_name, nil)
      |> assign(:invite_phone, nil)
      |> assign(:form_data, %{
        "names" => "",
        "email" => "",
        "phone" => "",
        "language" => "English",
        "id_type" => "National ID",
        "id_number" => "",
        "property" => "",
        "ownership_type" => "Freehold title",
        "lr_number" => "",
        "payout_method" => "M-Pesa",
        "payout_number" => "",
        "payout_name" => "",
        "comply" => false
      })

    socket =
      if token do
        case Accounts.get_invite_by_token(token) do
          {:ok, invite} ->
            case registration_role(invite) do
              nil ->
                socket
                |> assign(:invite, nil)
                |> assign(:invite_status, :invalid)

              role ->
                verification_request = Accounts.get_verification_request_by_email(invite.email)
                invite_name = if verification_request, do: verification_request.names, else: ""
                invite_phone = if verification_request, do: verification_request.phone, else: ""

                updated_data =
                  socket.assigns.form_data
                  |> Map.put("names", invite_name)
                  |> Map.put("email", invite.email)
                  |> Map.put("phone", invite_phone)
                  |> Map.put("payout_name", invite_name)

                socket
                |> assign(:invite, invite)
                |> assign(:role, role)
                |> assign(:invite_status, :valid)
                |> assign(:form_data, updated_data)
            end

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

  defp registration_role(%AdminLiteInvite{invite_type: "admin_lite"}), do: "admin_lite"
  defp registration_role(%AdminLiteInvite{invite_type: "landlord"}), do: "landlord"
  defp registration_role(_invite), do: nil

  defp role_dashboard_path("admin_lite"), do: ~p"/home"
  defp role_dashboard_path("landlord"), do: ~p"/house"
  defp role_dashboard_path(_role), do: ~p"/users/log-in"

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
  def handle_event("update_field", params, socket) do
    field = params["_target"] |> List.last()
    value = params[field]
    updated = Map.put(socket.assigns.form_data, field, value)
    {:noreply, assign(socket, :form_data, updated)}
  end

  @impl true
  def handle_event("next_step", params, socket) do
    merged = Map.merge(socket.assigns.form_data, Map.get(params, "form_data", %{}))
    current_step = socket.assigns.step
    next_step = min(current_step + 1, 5)

    {:noreply,
     socket
     |> assign(:form_data, merged)
     |> assign(:step, next_step)
     |> assign(:mobile_steps_open, false)}
  end

  @impl true
  def handle_event("prev_step", _params, socket) do
    prev_step = max(socket.assigns.step - 1, 1)
    {:noreply, assign(socket, step: prev_step, mobile_steps_open: false)}
  end

  @impl true
  def handle_event("go_to_step", %{"step" => step}, socket) do
    target = String.to_integer(step)
    {:noreply, assign(socket, step: target, mobile_steps_open: false)}
  end

  @impl true
  def handle_event("open_steps", _params, socket) do
    {:noreply, assign(socket, :mobile_steps_open, true)}
  end

  @impl true
  def handle_event("close_steps", _params, socket) do
    {:noreply, assign(socket, :mobile_steps_open, false)}
  end

  @impl true
  def handle_event("register", params, socket) do
    %AdminLiteInvite{} = invite = socket.assigns.invite
    role = socket.assigns.role
    form = Map.merge(socket.assigns.form_data, params)

    attrs = %{
      "names" => form["names"],
      "email" => invite.email,
      "phone" => form["phone"],
      "id_number" => form["id_number"],
      "password" => registration_password(role, form),
      "password_confirmation" => registration_password_confirmation(role, form),
      "role" => role
    }

    case Accounts.register_user(attrs) do
      {:ok, _user} ->
        Accounts.mark_invite_as_used(invite)

        {:noreply,
         socket
         |> put_flash(:info, "Account created and verified successfully!")
         |> redirect(to: role_dashboard_path(role))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form_data, Map.drop(form, ["password", "password_confirmation"]))
         |> assign(:registration_error, changeset_error_messages(changeset))}
    end
  end

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

  defp changeset_error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.flat_map(fn {field, messages} ->
      Enum.map(messages, fn message ->
        "#{field |> Atom.to_string() |> String.replace("_", " ")} #{message}"
      end)
    end)
  end

  defp registration_password("landlord", form), do: form["password"] || "DefaultPass123!"
  defp registration_password(_role, form), do: form["password"]

  defp registration_password_confirmation("landlord", form) do
    form["password_confirmation"] || registration_password("landlord", form)
  end

  defp registration_password_confirmation(_role, form), do: form["password_confirmation"]

  defp step_label(1), do: "Personal details"
  defp step_label(2), do: "Identity verification"
  defp step_label(3), do: "Proof of ownership"
  defp step_label(4), do: "Payout details"
  defp step_label(5), do: "Review & submit"

  defp step_items do
    [
      {1, "Personal details"},
      {2, "Identity verification"},
      {3, "Proof of ownership"},
      {4, "Payout details"},
      {5, "Review & submit"}
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
    id="both-register"
    phx-hook="HouseFinder"
    data-theme={@theme} class="min-h-screen">
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <link
        href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,500;0,600;0,700;1,500&family=Inter:wght@400;500;600;700&display=swap"
        rel="stylesheet"
      />

      <style>
        :root {
          --bg: #F1F4F9;
          --bg-grid: #DFE6F0;
          --panel: #FFFFFF;
          --panel-alt: #F7F9FC;
          --ink: #142030;
          --ink-dim: #5A6B80;
          --ink-faint: #94A2B5;
          --border: #DCE3EC;
          --accent: #1D4ED8;
          --accent-soft: #E6EDFB;
          --accent-ink: #FFFFFF;
          --gold: #9A6B12;
          --gold-soft: #FBF0DA;
          --danger: #B4483A;
          --shadow: 0 20px 50px -20px rgba(20,32,48,0.25);
        }
        [data-theme="dark"] {
          --bg: #0B1220;
          --bg-grid: #131C2C;
          --panel: #141E2F;
          --panel-alt: #101827;
          --ink: #E3EAF5;
          --ink-dim: #93A3BA;
          --ink-faint: #5D6E85;
          --border: #253248;
          --accent: #6AA6F5;
          --accent-soft: #17263F;
          --accent-ink: #0B1220;
          --gold: #D9A94C;
          --gold-soft: #2A2214;
          --danger: #E38B7A;
          --shadow: 0 20px 50px -20px rgba(0,0,0,0.6);
        }
        .kyc-page {
          background-color: var(--bg);
          background-image: radial-gradient(var(--bg-grid) 1px, transparent 1px);
          background-size: 22px 22px;
          color: var(--ink);
          font-family: 'Inter', sans-serif;
          transition: background-color .3s ease, color .3s ease;
        }
        .font-serif-display { font-family: 'Lora', serif; }
        .card { background-color: var(--panel); border: 1px solid var(--border); box-shadow: var(--shadow); }
        .panel-alt { background-color: var(--panel-alt); }
        .ink { color: var(--ink); }
        .ink-dim { color: var(--ink-dim); }
        .ink-faint { color: var(--ink-faint); }
        .border-token { border-color: var(--border); }
        .bg-accent { background-color: var(--accent); }
        .text-accent { color: var(--accent); }
        .bg-accent-soft { background-color: var(--accent-soft); }
        .text-gold { color: var(--gold); }
        .text-danger { color: var(--danger); }

        .field-input {
          background-color: var(--panel-alt);
          border: 1px solid var(--border);
          color: var(--ink);
          transition: all 0.2s ease;
        }
        .field-input::placeholder { color: var(--ink-faint); }
        .field-input:focus {
          outline: none;
          border-color: var(--accent);
          box-shadow: 0 0 0 3px var(--accent-soft);
        }
        .field-input[readonly] { color: var(--ink-dim); cursor: not-allowed; }

        .btn-primary {
          background-color: var(--accent);
          color: var(--accent-ink);
          transition: all 0.2s ease;
        }
        .btn-primary:hover { filter: brightness(1.08); }
        .btn-primary:disabled { opacity: .5; cursor: not-allowed; filter: none; }

        .btn-ghost {
          background-color: transparent;
          border: 1px solid var(--border);
          color: var(--ink);
          transition: all 0.2s ease;
        }
        .btn-ghost:hover { background-color: var(--panel-alt); }

        .rail-item[data-state="done"] .rail-dot { background-color: var(--accent); color: var(--accent-ink); border-color: var(--accent); }
        .rail-item[data-state="active"] .rail-dot { background-color: var(--accent-soft); color: var(--accent); border-color: var(--accent); }
        .rail-item[data-state="active"] .rail-label { color: var(--ink); }
        .rail-item[data-state="pending"] .rail-dot { background-color: transparent; color: var(--ink-faint); border-color: var(--border); }
        .rail-dot {
          width: 26px; height: 26px; border-radius: 9999px; border: 1px solid var(--border);
          display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 600;
          flex-shrink: 0;
        }
        .rail-label { color: var(--ink-faint); }

        .progress-track { background-color: var(--border); }
        .progress-fill { background-color: var(--accent); transition: width .45s cubic-bezier(.4,0,.2,1); }

        .file-drop {
          border: 1px dashed var(--border);
          background-color: var(--panel-alt);
        }
        .file-drop:hover { border-color: var(--accent); }
      </style>

      <div class="kyc-page min-h-screen flex items-center justify-center overflow-x-hidden p-3 sm:p-8">
        <div class="w-full max-w-4xl min-w-0">
          <%= case @invite_status do %>
            <% :valid -> %>
              <%= if @role == "admin_lite" do %>
                <div class="card rounded-2xl w-full max-w-xl mx-auto overflow-hidden">
                  <div class="px-6 sm:px-8 pt-6 pb-5 border-b border-token">
                    <div class="flex items-start justify-between gap-4">
                      <div>
                        <p class="text-xs font-semibold text-gold tracking-wide uppercase">
                          Admin onboarding
                        </p>
                        <h1 class="font-serif-display text-xl sm:text-2xl ink mt-0.5">
                          Create your staff account
                        </h1>
                        <p class="ink-dim text-sm mt-2">
                          Use the invite email below and add the details required to activate your access.
                        </p>
                      </div>
                      <button
                        type="button"
                        phx-click="toggle_theme"
                        class="btn-ghost rounded-full w-9 h-9 flex items-center justify-center shrink-0"
                        title="Toggle dark mode"
                      >
                        <%= if @theme == "dark" do %>
                          <svg
                            width="16"
                            height="16"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
                          </svg>
                        <% else %>
                          <svg
                            width="16"
                            height="16"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                          >
                            <path d="M21 12.8A9 9 0 1 1 11.2 3 7 7 0 0 0 21 12.8Z" />
                          </svg>
                        <% end %>
                      </button>
                    </div>
                  </div>

                  <div class="px-6 sm:px-8 py-6">
                    <%= if @registration_error do %>
                      <div
                        id="admin-lite-registration-errors"
                        class="mb-5 rounded-lg border border-token bg-accent-soft px-4 py-3"
                      >
                        <p class="text-sm font-semibold ink">Please check the details below.</p>
                        <ul class="mt-2 space-y-1 text-sm ink-dim">
                          <%= for error <- @registration_error do %>
                            <li>{error}</li>
                          <% end %>
                        </ul>
                      </div>
                    <% end %>

                    <form
                      id="admin-lite-registration-form"
                      phx-change="update_field"
                      phx-submit="register"
                      class="space-y-4"
                    >
                      <div>
                        <label class="block text-xs font-semibold ink-dim mb-1.5">Full name</label>
                        <input
                          id="admin-lite-names"
                          type="text"
                          name="names"
                          value={@form_data["names"]}
                          required
                          class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                        />
                      </div>
                      <div>
                        <label class="block text-xs font-semibold ink-dim mb-1.5">
                          Email address
                        </label>
                        <input
                          id="admin-lite-email"
                          type="email"
                          name="email"
                          value={@form_data["email"]}
                          readonly
                          class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                        />
                      </div>
                      <div>
                        <label class="block text-xs font-semibold ink-dim mb-1.5">
                          Phone number
                        </label>
                        <input
                          id="admin-lite-phone"
                          type="tel"
                          name="phone"
                          value={@form_data["phone"]}
                          required
                          placeholder="07XX XXX XXX"
                          class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                        />
                      </div>
                      <div>
                        <label class="block text-xs font-semibold ink-dim mb-1.5">ID number</label>
                        <input
                          id="admin-lite-id-number"
                          type="text"
                          name="id_number"
                          value={@form_data["id_number"]}
                          required
                          placeholder="e.g. 32011245"
                          class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                        />
                      </div>
                      <div>
                        <label class="block text-xs font-semibold ink-dim mb-1.5">Password</label>
                        <input
                          id="admin-lite-password"
                          type="password"
                          name="password"
                          required
                          minlength="6"
                          class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                        />
                      </div>
                      <div>
                        <label class="block text-xs font-semibold ink-dim mb-1.5">
                          Confirm password
                        </label>
                        <input
                          id="admin-lite-password-confirmation"
                          type="password"
                          name="password_confirmation"
                          required
                          minlength="6"
                          class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                        />
                      </div>
                      <button
                        id="admin-lite-submit"
                        type="submit"
                        class="btn-primary w-full rounded-lg py-3 text-sm font-semibold mt-2"
                      >
                        Create Admin Account
                      </button>
                    </form>
                  </div>
                </div>
              <% else %>
                <div class="card rounded-2xl w-full min-w-0 overflow-hidden">
                  <!-- Header -->
                  <div class="px-4 sm:px-8 pt-5 sm:pt-6 pb-5 border-b border-token">
                    <div class="flex items-start justify-between gap-4">
                      <div class="min-w-0">
                        <p class="text-xs font-semibold text-gold tracking-wide uppercase">
                          Landlord onboarding
                        </p>
                        <h1 class="font-serif-display text-xl sm:text-2xl ink mt-0.5">
                          Verification &amp; proof of ownership
                        </h1>
                      </div>
                      <div class="flex items-center gap-3 shrink-0">
                        <button
                          type="button"
                          phx-click="toggle_theme"
                          class="btn-ghost rounded-full w-9 h-9 flex items-center justify-center"
                          title="Toggle dark mode"
                        >
                          <%= if @theme == "dark" do %>
                            <svg
                              width="16"
                              height="16"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                            >
                              <circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
                            </svg>
                          <% else %>
                            <svg
                              width="16"
                              height="16"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                            >
                              <path d="M21 12.8A9 9 0 1 1 11.2 3 7 7 0 0 0 21 12.8Z" />
                            </svg>
                          <% end %>
                        </button>
                        <div class="text-right">
                          <p class="text-xs ink-faint">Progress</p>
                          <p class="font-serif-display text-lg ink">{@step * 20}%</p>
                        </div>
                      </div>
                    </div>
                    <div class="progress-track w-full h-1.5 rounded-full overflow-hidden mt-4">
                      <div class="progress-fill h-full rounded-full" style={"width: #{@step * 20}%"}>
                      </div>
                    </div>
                    <div class="sm:hidden mt-4">
                      <button
                        type="button"
                        phx-click="open_steps"
                        class="btn-ghost w-full rounded-lg px-4 py-3 text-left flex items-center justify-between gap-3"
                      >
                        <span class="min-w-0">
                          <span class="block text-[11px] font-semibold ink-faint uppercase tracking-wide">
                            Step {@step} of 5
                          </span>
                          <span class="block text-sm font-semibold ink truncate">
                            {step_label(@step)}
                          </span>
                        </span>
                        <svg
                          width="18"
                          height="18"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="currentColor"
                          stroke-width="2"
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          class="shrink-0"
                        >
                          <path d="M4 6h16M4 12h16M4 18h16" />
                        </svg>
                      </button>
                    </div>
                  </div>

                  <%= if @mobile_steps_open do %>
                    <div
                      class="fixed inset-0 z-50 sm:hidden bg-black/50"
                      phx-window-keydown="close_steps"
                      phx-key="escape"
                    >
                      <div
                        class="panel-alt absolute inset-y-0 left-0 w-[min(18rem,86vw)] border-r border-token px-5 py-5 shadow-2xl"
                        phx-click-away="close_steps"
                      >
                        <div class="flex items-center justify-between gap-4 mb-5">
                          <div>
                            <p class="text-xs font-semibold text-gold tracking-wide uppercase">
                              Landlord onboarding
                            </p>
                            <p class="font-serif-display text-lg ink mt-0.5">Steps</p>
                          </div>
                          <button
                            type="button"
                            phx-click="close_steps"
                            class="btn-ghost rounded-full w-9 h-9 flex items-center justify-center"
                          >
                            <svg
                              width="16"
                              height="16"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                            >
                              <path d="M18 6 6 18M6 6l12 12" />
                            </svg>
                          </button>
                        </div>

                        <ol class="flex flex-col gap-3">
                          <%= for {step, label} <- step_items() do %>
                            <li
                              class="rail-item cursor-pointer"
                              phx-click="go_to_step"
                              phx-value-step={step}
                              data-state={
                                cond do
                                  @step > step -> "done"
                                  @step == step -> "active"
                                  true -> "pending"
                                end
                              }
                            >
                              <button type="button" class="w-full flex items-start gap-3 text-left">
                                <span class="rail-dot">
                                  <%= if @step > step do %>
                                    <svg
                                      width="12"
                                      height="12"
                                      viewBox="0 0 24 24"
                                      fill="none"
                                      stroke="currentColor"
                                      stroke-width="3"
                                      stroke-linecap="round"
                                      stroke-linejoin="round"
                                    >
                                      <path d="M20 6 9 17l-5-5" />
                                    </svg>
                                  <% else %>
                                    {step}
                                  <% end %>
                                </span>
                                <span class="rail-label text-sm font-medium leading-6">
                                  {label}
                                </span>
                              </button>
                            </li>
                          <% end %>
                        </ol>
                      </div>
                    </div>
                  <% end %>

    <!-- Body: rail + step panels -->
                  <div class="flex flex-col sm:flex-row">
                    <!-- Rail -->
                    <aside class="hidden sm:block panel-alt sm:w-52 shrink-0 sm:border-r border-token px-5 sm:px-6 py-5">
                      <ol class="flex flex-col gap-5">
                        <li
                          class="rail-item flex items-center sm:items-start gap-3 shrink-0 cursor-pointer"
                          phx-click="go_to_step"
                          phx-value-step="1"
                          data-state={
                            if @step > 1,
                              do: "done",
                              else: if(@step == 1, do: "active", else: "pending")
                          }
                        >
                          <span class="rail-dot">
                            <%= if @step > 1 do %>
                              <svg
                                width="12"
                                height="12"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="3"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                              >
                                <path d="M20 6 9 17l-5-5" />
                              </svg>
                            <% else %>
                              1
                            <% end %>
                          </span>
                          <span class="rail-label text-xs sm:text-sm font-medium whitespace-nowrap sm:whitespace-normal">
                            Personal details
                          </span>
                        </li>

                        <li
                          class="rail-item flex items-center sm:items-start gap-3 shrink-0 cursor-pointer"
                          phx-click="go_to_step"
                          phx-value-step="2"
                          data-state={
                            if @step > 2,
                              do: "done",
                              else: if(@step == 2, do: "active", else: "pending")
                          }
                        >
                          <span class="rail-dot">
                            <%= if @step > 2 do %>
                              <svg
                                width="12"
                                height="12"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="3"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                              >
                                <path d="M20 6 9 17l-5-5" />
                              </svg>
                            <% else %>
                              2
                            <% end %>
                          </span>
                          <span class="rail-label text-xs sm:text-sm font-medium whitespace-nowrap sm:whitespace-normal">
                            Identity verification
                          </span>
                        </li>

                        <li
                          class="rail-item flex items-center sm:items-start gap-3 shrink-0 cursor-pointer"
                          phx-click="go_to_step"
                          phx-value-step="3"
                          data-state={
                            if @step > 3,
                              do: "done",
                              else: if(@step == 3, do: "active", else: "pending")
                          }
                        >
                          <span class="rail-dot">
                            <%= if @step > 3 do %>
                              <svg
                                width="12"
                                height="12"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="3"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                              >
                                <path d="M20 6 9 17l-5-5" />
                              </svg>
                            <% else %>
                              3
                            <% end %>
                          </span>
                          <span class="rail-label text-xs sm:text-sm font-medium whitespace-nowrap sm:whitespace-normal">
                            Proof of ownership
                          </span>
                        </li>

                        <li
                          class="rail-item flex items-center sm:items-start gap-3 shrink-0 cursor-pointer"
                          phx-click="go_to_step"
                          phx-value-step="4"
                          data-state={
                            if @step > 4,
                              do: "done",
                              else: if(@step == 4, do: "active", else: "pending")
                          }
                        >
                          <span class="rail-dot">
                            <%= if @step > 4 do %>
                              <svg
                                width="12"
                                height="12"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="3"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                              >
                                <path d="M20 6 9 17l-5-5" />
                              </svg>
                            <% else %>
                              4
                            <% end %>
                          </span>
                          <span class="rail-label text-xs sm:text-sm font-medium whitespace-nowrap sm:whitespace-normal">
                            Payout details
                          </span>
                        </li>

                        <li
                          class="rail-item flex items-center sm:items-start gap-3 shrink-0 cursor-pointer"
                          phx-click="go_to_step"
                          phx-value-step="5"
                          data-state={if @step == 5, do: "active", else: "pending"}
                        >
                          <span class="rail-dot">5</span>
                          <span class="rail-label text-xs sm:text-sm font-medium whitespace-nowrap sm:whitespace-normal">
                            Review &amp; submit
                          </span>
                        </li>
                      </ol>
                    </aside>

    <!-- Steps Form Container -->
                    <main class="flex-1 min-w-0 px-4 sm:px-8 py-5 sm:py-6 min-h-[380px]">
                      <form id="landlord-kyc-form" phx-change="update_field" phx-submit="register">
                        <!-- STEP 1 -->
                        <section class={if @step == 1, do: "block", else: "hidden"}>
                          <h2 class="font-serif-display text-lg ink mb-1">Personal details</h2>
                          <p class="ink-dim text-sm mb-5">
                            Use the invite email below and add the details required for verification.
                          </p>
                          <div class="grid sm:grid-cols-2 gap-4">
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Full name
                              </label>
                              <input
                                type="text"
                                name="names"
                                value={@form_data["names"]}
                                required
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Email address
                              </label>
                              <input
                                type="email"
                                name="email"
                                value={@form_data["email"]}
                                readonly
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Phone number
                              </label>
                              <input
                                type="tel"
                                name="phone"
                                value={@form_data["phone"]}
                                placeholder="07XX XXX XXX"
                                required
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Preferred language
                              </label>
                              <select
                                name="language"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              >
                                <option selected={@form_data["language"] == "English"}>
                                  English
                                </option>
                                <option selected={@form_data["language"] == "Kiswahili"}>
                                  Kiswahili
                                </option>
                              </select>
                            </div>
                          </div>
                        </section>

    <!-- STEP 2 -->
                        <section class={if @step == 2, do: "block", else: "hidden"}>
                          <h2 class="font-serif-display text-lg ink mb-1">Identity verification</h2>
                          <p class="ink-dim text-sm mb-5">
                            Your ID must be valid and clearly legible.
                          </p>
                          <div class="grid sm:grid-cols-2 gap-4">
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                ID type
                              </label>
                              <select
                                name="id_type"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              >
                                <option selected={@form_data["id_type"] == "National ID"}>
                                  National ID
                                </option>
                                <option selected={@form_data["id_type"] == "Passport"}>
                                  Passport
                                </option>
                                <option selected={@form_data["id_type"] == "Alien ID"}>
                                  Alien ID
                                </option>
                              </select>
                            </div>
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                ID / passport number
                              </label>
                              <input
                                type="text"
                                name="id_number"
                                value={@form_data["id_number"]}
                                placeholder="e.g. 32011245"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                ID &mdash; front
                              </label>
                              <label class="file-drop rounded-lg px-4 py-4 flex items-center gap-3 cursor-pointer">
                                <svg
                                  width="18"
                                  height="18"
                                  viewBox="0 0 24 24"
                                  fill="none"
                                  stroke="currentColor"
                                  class="text-accent shrink-0"
                                  stroke-width="2"
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                >
                                  <path d="M12 16V4M12 4 7 9M12 4l5 5" /><path d="M20 16v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-3" />
                                </svg>
                                <span class="min-w-0 break-words text-xs ink-dim">
                                  Upload photo or scan
                                </span>
                                <input type="file" class="hidden" accept="image/*,.pdf" />
                              </label>
                            </div>
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                ID &mdash; back
                              </label>
                              <label class="file-drop rounded-lg px-4 py-4 flex items-center gap-3 cursor-pointer">
                                <svg
                                  width="18"
                                  height="18"
                                  viewBox="0 0 24 24"
                                  fill="none"
                                  stroke="currentColor"
                                  class="text-accent shrink-0"
                                  stroke-width="2"
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                >
                                  <path d="M12 16V4M12 4 7 9M12 4l5 5" /><path d="M20 16v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-3" />
                                </svg>
                                <span class="min-w-0 break-words text-xs ink-dim">
                                  Upload photo or scan
                                </span>
                                <input type="file" class="hidden" accept="image/*,.pdf" />
                              </label>
                            </div>
                          </div>
                        </section>

    <!-- STEP 3 -->
                        <section class={if @step == 3, do: "block", else: "hidden"}>
                          <h2 class="font-serif-display text-lg ink mb-1">Proof of ownership</h2>
                          <p class="ink-dim text-sm mb-5">
                            Add the property and the document that proves you own or manage it.
                          </p>
                          <div class="grid sm:grid-cols-2 gap-4">
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Property name / address
                              </label>
                              <input
                                type="text"
                                name="property"
                                value={@form_data["property"]}
                                placeholder="e.g. Kilimani Heights, Nairobi"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Ownership type
                              </label>
                              <select
                                name="ownership_type"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              >
                                <option selected={@form_data["ownership_type"] == "Freehold title"}>
                                  Freehold title
                                </option>
                                <option selected={@form_data["ownership_type"] == "Leasehold title"}>
                                  Leasehold title
                                </option>
                                <option selected={@form_data["ownership_type"] == "Sectional title"}>
                                  Sectional title
                                </option>
                                <option selected={
                                  @form_data["ownership_type"] ==
                                    "Power of attorney / management agreement"
                                }>
                                  Power of attorney / management agreement
                                </option>
                              </select>
                            </div>
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Title deed / LR number
                              </label>
                              <input
                                type="text"
                                name="lr_number"
                                value={@form_data["lr_number"]}
                                placeholder="e.g. Nairobi/Block 99/145"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Ownership document
                              </label>
                              <label class="file-drop rounded-lg px-4 py-4 flex items-center gap-3 cursor-pointer">
                                <svg
                                  width="18"
                                  height="18"
                                  viewBox="0 0 24 24"
                                  fill="none"
                                  stroke="currentColor"
                                  class="text-accent shrink-0"
                                  stroke-width="2"
                                  stroke-linecap="round"
                                  stroke-linejoin="round"
                                >
                                  <path d="M12 16V4M12 4 7 9M12 4l5 5" /><path d="M20 16v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-3" />
                                </svg>
                                <span class="min-w-0 break-words text-xs ink-dim">
                                  Title deed, lease, or management agreement (PDF)
                                </span>
                                <input type="file" class="hidden" accept="image/*,.pdf" />
                              </label>
                            </div>
                          </div>
                        </section>

    <!-- STEP 4 -->
                        <section class={if @step == 4, do: "block", else: "hidden"}>
                          <h2 class="font-serif-display text-lg ink mb-1">Payout details</h2>
                          <p class="ink-dim text-sm mb-5">
                            The name on this account must match your registered name.
                          </p>
                          <div class="grid sm:grid-cols-2 gap-4">
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Payout method
                              </label>
                              <select
                                name="payout_method"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              >
                                <option selected={@form_data["payout_method"] == "M-Pesa"}>
                                  M-Pesa
                                </option>
                                <option selected={@form_data["payout_method"] == "Bank transfer"}>
                                  Bank transfer
                                </option>
                              </select>
                            </div>
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Account / mobile number
                              </label>
                              <input
                                type="text"
                                name="payout_number"
                                value={@form_data["payout_number"]}
                                placeholder="e.g. 07XX XXX XXX"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Account name
                              </label>
                              <input
                                type="text"
                                name="payout_name"
                                value={@form_data["payout_name"]}
                                placeholder="Must match full name above"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>
                          </div>
                        </section>

    <!-- STEP 5 -->
                        <section class={if @step == 5, do: "block", else: "hidden"}>
                          <h2 class="font-serif-display text-lg ink mb-1">Review &amp; submit</h2>
                          <p class="ink-dim text-sm mb-5">
                            Check everything below before you send it for review.
                          </p>

                          <%= if @registration_error do %>
                            <div
                              id="landlord-registration-errors"
                              class="mb-5 rounded-lg border border-token bg-accent-soft px-4 py-3"
                            >
                              <p class="text-sm font-semibold ink">Please check the details below.</p>
                              <ul class="mt-2 space-y-1 text-sm ink-dim">
                                <%= for error <- @registration_error do %>
                                  <li>{error}</li>
                                <% end %>
                              </ul>
                            </div>
                          <% end %>

                          <div class="space-y-2 text-sm rounded-lg border border-token panel-alt p-4">
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 sm:gap-4 py-1 border-b border-token/50">
                              <span class="ink-faint shrink-0">Full name</span>
                              <span class="ink min-w-0 break-words font-medium sm:text-right">
                                {@form_data["names"]}
                              </span>
                            </div>
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 sm:gap-4 py-1 border-b border-token/50">
                              <span class="ink-faint shrink-0">Email</span>
                              <span class="ink min-w-0 break-all font-medium sm:text-right">
                                {@form_data["email"]}
                              </span>
                            </div>
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 sm:gap-4 py-1 border-b border-token/50">
                              <span class="ink-faint shrink-0">Phone</span>
                              <span class="ink min-w-0 break-words font-medium sm:text-right">
                                {@form_data["phone"]}
                              </span>
                            </div>
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 sm:gap-4 py-1 border-b border-token/50">
                              <span class="ink-faint shrink-0">ID type &amp; number</span>
                              <span class="ink min-w-0 break-words font-medium sm:text-right">
                                {@form_data["id_type"]} - {@form_data["id_number"]}
                              </span>
                            </div>
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 sm:gap-4 py-1 border-b border-token/50">
                              <span class="ink-faint shrink-0">Property</span>
                              <span class="ink min-w-0 break-words font-medium sm:text-right">
                                {@form_data["property"]}
                              </span>
                            </div>
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 sm:gap-4 py-1 border-b border-token/50">
                              <span class="ink-faint shrink-0">Ownership type</span>
                              <span class="ink min-w-0 break-words font-medium sm:text-right">
                                {@form_data["ownership_type"]}
                              </span>
                            </div>
                            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1 sm:gap-4 py-1">
                              <span class="ink-faint shrink-0">Payout account</span>
                              <span class="ink min-w-0 break-words font-medium sm:text-right">
                                {@form_data["payout_method"]} ({@form_data["payout_number"]})
                              </span>
                            </div>
                          </div>

                          <label class="flex items-start gap-2.5 mt-5 cursor-pointer">
                            <input
                              type="checkbox"
                              name="comply"
                              value="true"
                              checked={@form_data["comply"]}
                              required
                              class="mt-0.5 rounded border-token"
                            />
                            <span class="text-xs ink-dim leading-relaxed">
                              I confirm the information above is accurate and I agree to the landlord verification rules.
                            </span>
                          </label>
                        </section>
                      </form>
                    </main>
                  </div>

    <!-- Footer Navigation -->
                  <div class="px-4 sm:px-8 py-4 border-t border-token flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                    <button
                      type="button"
                      class="btn-ghost w-full sm:w-auto rounded-lg px-4 py-2.5 text-xs sm:text-sm font-semibold"
                    >
                      Save &amp; continue later
                    </button>
                    <div class="grid grid-cols-2 sm:flex sm:items-center gap-3 w-full sm:w-auto">
                      <button
                        type="button"
                        phx-click="prev_step"
                        disabled={@step == 1}
                        class="btn-ghost rounded-lg px-5 py-2.5 text-xs sm:text-sm font-semibold"
                      >
                        Back
                      </button>

                      <%= if @step < 5 do %>
                        <button
                          type="button"
                          phx-click="next_step"
                          class="btn-primary rounded-lg px-6 py-2.5 text-xs sm:text-sm font-semibold"
                        >
                          Continue
                        </button>
                      <% else %>
                        <button
                          type="submit"
                          form="landlord-kyc-form"
                          class="btn-primary rounded-lg px-6 py-2.5 text-xs sm:text-sm font-semibold"
                        >
                          Submit for verification
                        </button>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            <% :already_used -> %>
              <div class="card rounded-2xl w-full max-w-md mx-auto text-center p-8 space-y-4">
                <div class="w-12 h-12 mx-auto rounded-full bg-gold-soft text-gold flex items-center justify-center">
                  <svg
                    width="24"
                    height="24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    viewBox="0 0 24 24"
                  >
                    <path d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>
                </div>
                <h2 class="font-serif-display text-xl ink">Invite Link Already Used</h2>
                <p class="ink-dim text-sm">This invitation token has already been redeemed.</p>
                <.link
                  navigate={~p"/users/log-in"}
                  class="btn-primary inline-block w-full rounded-lg py-3 text-sm font-semibold mt-4"
                >
                  Go to Sign In
                </.link>
              </div>
            <% :invalid -> %>
              <div class="card rounded-2xl w-full max-w-md mx-auto text-center p-8 space-y-4">
                <div class="w-12 h-12 mx-auto rounded-full bg-accent-soft text-accent flex items-center justify-center">
                  <svg
                    width="24"
                    height="24"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="2"
                    viewBox="0 0 24 24"
                  >
                    <path d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </div>
                <h2 class="font-serif-display text-xl ink">Invalid Invitation</h2>
                <p class="ink-dim text-sm">The invitation link is expired or invalid.</p>
                <.link
                  navigate={~p"/verification"}
                  class="btn-primary inline-block w-full rounded-lg py-3 text-sm font-semibold mt-4"
                >
                  Request Verification
                </.link>
              </div>
            <% :none -> %>
              <div class="card rounded-2xl w-full max-w-md mx-auto p-8">
                <div class="mb-6 border-b border-token pb-4">
                  <p class="text-xs font-semibold text-gold tracking-wide uppercase">
                    Landlord Portal
                  </p>
                  <h1 class="font-serif-display text-xl ink mt-0.5">Request Verification</h1>
                </div>

                <%= if @request_submitted do %>
                  <div class="text-center space-y-4">
                    <div class="w-12 h-12 mx-auto rounded-full bg-accent-soft text-accent flex items-center justify-center">
                      <svg
                        width="20"
                        height="20"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        viewBox="0 0 24 24"
                      >
                        <path d="M20 6 9 17l-5-5" />
                      </svg>
                    </div>
                    <h2 class="font-serif-display text-lg ink">Verification Request Sent</h2>
                    <p class="ink-dim text-sm">
                      Our admin team will review your submission and email you an access link shortly.
                    </p>
                  </div>
                <% else %>
                  <form phx-submit="submit_verification_request" class="space-y-4">
                    <div>
                      <label class="block text-xs font-semibold ink-dim mb-1.5">Full Name</label>
                      <input
                        type="text"
                        name="names"
                        required
                        class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-semibold ink-dim mb-1.5">Email Address</label>
                      <input
                        type="email"
                        name="email"
                        required
                        class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-semibold ink-dim mb-1.5">Phone Number</label>
                      <input
                        type="tel"
                        name="phone"
                        required
                        class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                      />
                    </div>
                    <button
                      type="submit"
                      class="btn-primary w-full rounded-lg py-3 text-sm font-semibold mt-2"
                    >
                      Submit Request
                    </button>
                  </form>
                <% end %>
              </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
