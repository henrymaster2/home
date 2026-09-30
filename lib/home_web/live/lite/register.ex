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
      |> assign(:invite, nil)
      |> assign(:invite_status, :none)
      |> assign(:form_data, default_form_data())
      |> allow_upload(:ownership_doc,
        accept: ~w(.jpg .jpeg .png .pdf),
        max_entries: 1,
        auto_upload: true,
        max_file_size: 10_000_000
      )
      |> allow_upload(:id_front,
        accept: ~w(.jpg .jpeg .png .pdf),
        max_entries: 1,
        auto_upload: true,
        max_file_size: 10_000_000
      )
      |> allow_upload(:id_back,
        accept: ~w(.jpg .jpeg .png .pdf),
        max_entries: 1,
        auto_upload: true,
        max_file_size: 10_000_000
      )
      |> allow_upload(:kra_doc,
        accept: ~w(.jpg .jpeg .png .pdf),
        max_entries: 1,
        auto_upload: true,
        max_file_size: 10_000_000
      )

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
                saved_draft = (verification_request && verification_request.draft_data) || %{}
                saved_step = (verification_request && verification_request.draft_step) || 1

                form_data =
                  default_form_data()
                  |> Map.merge(saved_draft)
                  |> Map.put("names", invite_name)
                  |> Map.put("email", invite.email)
                  |> Map.put("phone", invite_phone)
                  |> put_default("whatsapp_phone", invite_phone)
                  |> put_default("payout_name", invite_name)
                  |> put_default("billing_phone", invite_phone)

                socket
                |> assign(:invite, invite)
                |> assign(:role, role)
                |> assign(:invite_status, :valid)
                |> assign(:form_data, form_data)
                |> assign(:step, saved_step)
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
  @impl true
  def handle_event("save_draft", params, socket) do
    case socket.assigns.invite do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Cannot save draft without a valid invitation link.")}

      invite ->
        {uploaded_urls, upload_errors} = consume_all_uploads(socket)

        form_data =
          socket.assigns.form_data
          |> Map.merge(Map.drop(params, ["_target"]))
          |> Map.merge(uploaded_urls)

        verification_request = Accounts.get_verification_request_by_email(invite.email)
        request_attrs = verification_request_attrs(invite, form_data)

        if upload_errors == [] do
          case Accounts.save_verification_draft(
                 verification_request,
                 request_attrs,
                 form_data,
                 socket.assigns.step
               ) do
            {:ok, _updated_req} ->
              {:noreply,
               socket
               |> assign(:form_data, form_data)
               |> put_flash(
                 :info,
                 "Progress saved! You can safely close this page and return using your link anytime."
               )}

            {:error, _changeset} ->
              {:noreply,
               socket
               |> put_flash(:error, "Failed to save draft progress. Please try again.")}
          end
        else
          {:noreply,
           socket
           |> assign(:form_data, form_data)
           |> put_flash(:error, upload_error_message(upload_errors))}
        end
    end
  end

  defp consume_all_uploads(socket) do
    [
      {:id_front, "id_front_url"},
      {:id_back, "id_back_url"},
      {:kra_doc, "kra_doc_url"},
      {:ownership_doc, "ownership_doc_url"}
    ]
    |> Enum.reduce({%{}, []}, fn {upload_name, url_key}, {uploaded, errors} ->
      {upload_data, upload_errors} = consume_document_upload(socket, upload_name, url_key)

      {
        Map.merge(uploaded, upload_data),
        errors ++ upload_errors
      }
    end)
  end

  defp consume_document_upload(socket, upload_name, url_key) do
    entries =
      consume_uploaded_entries(socket, upload_name, fn %{path: path}, entry ->
        case Home.Cloudinary.upload(path) do
          {:ok, url} ->
            {:ok,
             %{
               "url" => url,
               "meta" => %{
                 "original_filename" => entry.client_name,
                 "content_type" => entry.client_type
               }
             }}

          {:error, reason} ->
            {:ok, %{"error" => reason}}
        end
      end)

    case List.first(entries) do
      %{"error" => reason} ->
        {%{}, [{upload_name, reason}]}

      %{"url" => url, "meta" => metadata} ->
        {%{url_key => url, "#{upload_name}_meta" => metadata}, []}

      nil ->
        existing_url = socket.assigns.form_data[url_key]
        existing_metadata = socket.assigns.form_data["#{upload_name}_meta"]

        if existing_url in [nil, ""] do
          {%{}, []}
        else
          {%{url_key => existing_url, "#{upload_name}_meta" => existing_metadata || %{}}, []}
        end
    end
  end

  defp upload_error_message(upload_errors) do
    failed_documents =
      upload_errors
      |> Enum.map(fn {upload_name, _reason} -> upload_label(upload_name) end)
      |> Enum.join(", ")

    "Could not upload #{failed_documents}. Please try again before saving."
  end

  defp upload_label(:id_front), do: "ID front"
  defp upload_label(:id_back), do: "ID back"
  defp upload_label(:kra_doc), do: "KRA document"
  defp upload_label(:ownership_doc), do: "ownership document"
  defp upload_label(other), do: to_string(other)

  defp image_entry?(entry), do: String.starts_with?(entry.client_type || "", "image/")

  defp image_url?(url) when is_binary(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> to_string()
    |> String.downcase()
    |> String.match?(~r/\.(jpe?g|png|gif|webp)$/)
  end

  defp image_url?(_url), do: false

  defp document_present?(form_data, url_key), do: form_data[url_key] not in [nil, ""]

  defp document_status(form_data, url_key, entries, label) do
    cond do
      entries != [] -> "#{label} attached"
      document_present?(form_data, url_key) -> "#{label} saved"
      true -> "#{label} missing"
    end
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref, "upload" => upload}, socket) do
    upload_atom = String.to_existing_atom(upload)
    {:noreply, cancel_upload(socket, upload_atom, ref)}
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
  def handle_event("update_field", params, socket) do
    field = params["_target"] |> List.last()
    value = params[field]
    updated = Map.put(socket.assigns.form_data, field, value)
    {:noreply, assign(socket, :form_data, updated)}
  end

  @impl true
  # 1. Step 2 -> Step 3: Consume ID uploads into Cloudinary
def handle_event("next_step", params, %{assigns: %{step: 2}} = socket) do
  merged = Map.merge(socket.assigns.form_data, Map.get(params, "form_data", %{}))

  id_front_urls = consume_uploaded_entries(socket, :id_front, &upload_verification_doc/2)
  id_back_urls = consume_uploaded_entries(socket, :id_back, &upload_verification_doc/2)
  kra_doc_urls = consume_uploaded_entries(socket, :kra_doc, &upload_verification_doc/2)

  updated_form_data =
    merged
    |> Map.put("id_front_url", extract_url(id_front_urls) || merged["id_front_url"])
    |> Map.put("id_back_url", extract_url(id_back_urls) || merged["id_back_url"])
    |> Map.put("kra_doc_url", extract_url(kra_doc_urls) || merged["kra_doc_url"])

  {:noreply,
   socket
   |> assign(:form_data, updated_form_data)
   |> assign(:step, 3)
   |> assign(:mobile_steps_open, false)}
end

# Private helper to ensure only binary URLs are returned
defp extract_url([url | _]) when is_binary(url), do: url
defp extract_url(_), do: nil

@impl true
# 2. Step 3 -> Step 4: Consume Proof of Ownership upload into Cloudinary
def handle_event("next_step", params, %{assigns: %{step: 3}} = socket) do
  merged = Map.merge(socket.assigns.form_data, Map.get(params, "form_data", %{}))

  ownership_doc_urls = consume_uploaded_entries(socket, :ownership_doc, &upload_verification_doc/2)

  updated_form_data =
    merged
    |> Map.put("ownership_doc_url", List.first(ownership_doc_urls) || merged["ownership_doc_url"])

  {:noreply,
   socket
   |> assign(:form_data, updated_form_data)
   |> assign(:step, 4)
   |> assign(:mobile_steps_open, false)}
end

@impl true
# 3. Fallback: Handles remaining step transitions (Step 1 -> 2, Step 4 -> 5)
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
  defp upload_verification_doc(%{path: path}, _entry) do
  # Calls your Cloudinary module, passing the verification folder
  Home.Cloudinary.upload(path, "verifications/landlord_docs")
end

@impl true
 defp upload_verification_doc(%{path: path}, _entry) do
  case Home.Cloudinary.upload(path, "verifications/landlord_docs") do
    {:ok, url} ->
      {:ok, url}

    {:error, reason} ->
      # Log or handle the failure gracefully
      {:postpone, reason} # or handle error response
  end
end
  @impl true
  def handle_event("go_to_step", %{"step" => step}, socket) do
    target = String.to_integer(step)
    {:noreply, assign(socket, step: target, mobile_steps_open: false)}
  end


def handle_event("prev_step", _params, %{assigns: %{step: step}} = socket) when step > 1 do
  {:noreply, assign(socket, :step, step - 1)}
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
    invite = socket.assigns.invite
    role = socket.assigns.role

    case role do
      "admin_lite" ->
        register_admin_lite(params, invite, socket)

      "landlord" ->
        register_landlord(params, invite, socket)

      _ ->
        {:noreply, put_flash(socket, :error, "Invalid registration role.")}
    end
  end

  defp register_admin_lite(params, invite, socket) do
    form = Map.merge(socket.assigns.form_data, params)

    attrs = %{
      "names" => form["names"],
      "email" => invite.email,
      "phone" => form["phone"],
      "id_number" => form["id_number"],
      "password" => registration_password("admin_lite", form),
      "password_confirmation" => registration_password_confirmation("admin_lite", form),
      "role" => "admin_lite"
    }

    case Accounts.register_user(attrs) do
      {:ok, _user} ->
        Accounts.mark_invite_as_used(invite)

        {:noreply,
         socket
         |> put_flash(:info, "Account created and verified successfully!")
         |> redirect(to: role_dashboard_path("admin_lite"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form_data, Map.drop(form, ["password", "password_confirmation"]))
         |> assign(:registration_error, changeset_error_messages(changeset))}
    end
  end

  defp register_landlord(params, invite, socket) do
    {uploaded_urls, upload_errors} = consume_all_uploads(socket)

    form_data =
      socket.assigns.form_data
      |> Map.merge(Map.drop(params, ["_target"]))
      |> Map.merge(uploaded_urls)

    if upload_errors == [] do
      case Accounts.complete_landlord_registration(invite, form_data) do
        {:ok, _landlord} ->
          Accounts.mark_invite_as_used(invite)

          {:noreply,
           socket
           |> put_flash(:info, "Landlord registration submitted successfully!")
           |> redirect(to: role_dashboard_path("landlord"))}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(:form_data, Map.drop(form_data, ["password", "password_confirmation"]))
           |> assign(:registration_error, changeset_error_messages(changeset))}
      end
    else
      {:noreply,
       socket
       |> assign(:form_data, Map.drop(form_data, ["password", "password_confirmation"]))
       |> put_flash(:error, upload_error_message(upload_errors))}
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

  defp registration_role(%AdminLiteInvite{invite_type: "admin_lite"}), do: "admin_lite"
  defp registration_role(%AdminLiteInvite{invite_type: "landlord"}), do: "landlord"
  defp registration_role(_invite), do: nil

  defp role_dashboard_path("admin_lite"), do: ~p"/home"
  defp role_dashboard_path("landlord"), do: ~p"/house"
  defp role_dashboard_path(_role), do: ~p"/users/log-in"

  defp default_form_data do
    %{
      "entity_type" => "individual",
      "names" => "",
      "email" => "",
      "phone" => "",
      "whatsapp_phone" => "",
      "residence_location" => "",
      "id_type" => "National ID",
      "id_number" => "",
      "kra_pin" => "",
      "id_front_url" => "",
      "id_back_url" => "",
      "kra_doc_url" => "",
      "property" => "",
      "ownership_type" => "Freehold title",
      "lr_number" => "",
      "billing_method" => "M-Pesa",
      "billing_phone" => "",
      "enable_payouts" => false,
      "payout_method" => "M-Pesa",
      "payout_number" => "",
      "payout_name" => "",
      "comply" => false,
      "listing_purpose" => "renting",
      "property_name" => "",
      "property_location" => "",
      "total_units" => "",
      "ownership_doc_url" => ""
    }
  end

  defp verification_request_attrs(invite, form_data) do
    %{
      "names" => blank_to_default(form_data["names"], invite.email),
      "email" => invite.email,
      "phone" => blank_to_default(form_data["phone"], "pending")
    }
  end

  defp blank_to_default(nil, default), do: default
  defp blank_to_default("", default), do: default
  defp blank_to_default(value, _default), do: value

  defp put_default(form_data, key, default) do
    Map.update(form_data, key, default, &blank_to_default(&1, default))
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
    <div id="both-register" phx-hook="HouseFinder" data-theme={@theme} class="min-h-screen">
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
                      class="fixed inset-0 z-50 sm:hidden bg-black/20 backdrop-blur-[1px] px-3 pt-32"
                      phx-window-keydown="close_steps"
                      phx-key="escape"
                    >
                      <div
                        class="mx-auto w-full max-w-[26rem] max-h-[70vh] overflow-y-auto rounded-2xl border border-token px-4 py-4 shadow-2xl"
                        style="background: color-mix(in srgb, var(--panel) 84%, transparent); backdrop-filter: blur(18px); -webkit-backdrop-filter: blur(18px);"
                        phx-click-away="close_steps"
                      >
                        <div class="flex items-center justify-between gap-4 mb-4">
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

                        <ol class="flex flex-col gap-2.5">
                          <%= for {step, label} <- step_items() do %>
                            <li
                              class="rail-item cursor-pointer rounded-xl px-2.5 py-2 transition"
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
                              <button type="button" class="w-full flex items-center gap-3 text-left">
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
                        <!-- STEP 1 -->
                        <section class={if @step == 1, do: "block", else: "hidden"}>
                          <h2 class="font-serif-display text-lg ink mb-1">Personal details</h2>
                          <p class="ink-dim text-sm mb-5">
                            Provide your primary personal information for verification.
                          </p>
                          <div class="grid sm:grid-cols-2 gap-4">
                            <!-- Entity Type -->
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Landlord category
                              </label>
                              <div class="grid grid-cols-2 gap-3">
                                <label class="flex items-center gap-2 border border-token rounded-lg p-3 cursor-pointer panel-alt">
                                  <input
                                    type="radio"
                                    name="entity_type"
                                    value="individual"
                                    checked={@form_data["entity_type"] == "individual"}
                                    class="text-accent"
                                  />
                                  <span class="text-xs font-medium ink">Individual Landlord</span>
                                </label>
                                <label class="flex items-center gap-2 border border-token rounded-lg p-3 cursor-pointer panel-alt">
                                  <input
                                    type="radio"
                                    name="entity_type"
                                    value="company"
                                    checked={@form_data["entity_type"] == "company"}
                                    class="text-accent"
                                  />
                                  <span class="text-xs font-medium ink">Company / Business</span>
                                </label>
                              </div>
                            </div>

    <!-- Full / Business Name -->
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                {if @form_data["entity_type"] == "company",
                                  do: "Company / Business name",
                                  else: "Full name"}
                              </label>
                              <input
                                type="text"
                                name="names"
                                value={@form_data["names"]}
                                required
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>

    <!-- Email Address (Read-only) -->
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

    <!-- Primary Phone -->
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Primary phone number
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

    <!-- WhatsApp Phone -->
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                WhatsApp number
                              </label>
                              <input
                                type="tel"
                                name="whatsapp_phone"
                                value={@form_data["whatsapp_phone"]}
                                placeholder="07XX XXX XXX"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>

    <!-- Residence Location -->
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                County / Town of residence
                              </label>
                              <input
                                type="text"
                                name="residence_location"
                                value={@form_data["residence_location"]}
                                placeholder="e.g. Nairobi, Kisii, Kiambu"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>
                          </div>
                        </section>

    <!-- STEP 2 -->

                   <section class={if @step == 2, do: "block", else: "hidden"}>
  <h2 class="font-serif-display text-lg ink mb-1">Identity verification</h2>
  <p class="ink-dim text-sm mb-5">
    <%= if @form_data["entity_type"] == "company" do %>
      Upload legal business registration details and tax documentation.
    <% else %>
      Provide your legal identity documents and tax PIN.
    <% end %>
  </p>
  <div class="grid sm:grid-cols-2 gap-4">
    <!-- ID Type -->
    <div>
      <label class="block text-xs font-semibold ink-dim mb-1.5">
        {if @form_data["entity_type"] == "company",
          do: "Document type",
          else: "ID type"}
      </label>
      <select
        name="id_type"
        class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
      >
        <%= if @form_data["entity_type"] == "company" do %>
          <option selected={
            @form_data["id_type"] == "Certificate of Incorporation"
          }>
            Certificate of Incorporation
          </option>
          <option selected={@form_data["id_type"] == "Business Registration"}>
            Business Registration
          </option>
        <% else %>
          <option selected={@form_data["id_type"] == "National ID"}>
            National ID
          </option>
          <option selected={@form_data["id_type"] == "Passport"}>
            Passport
          </option>
          <option selected={@form_data["id_type"] == "Alien ID"}>
            Alien ID
          </option>
        <% end %>
      </select>
    </div>

    <!-- ID Number -->
    <div>
      <label class="block text-xs font-semibold ink-dim mb-1.5">
        {if @form_data["entity_type"] == "company",
          do: "Registration / CPR number",
          else: "ID / Passport number"}
      </label>
      <input
        type="text"
        name="id_number"
        value={@form_data["id_number"]}
        placeholder={
          if @form_data["entity_type"] == "company",
            do: "e.g. PVT-AB1234",
            else: "e.g. 32011245"
        }
        class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
      />
    </div>

    <!-- KRA PIN -->
    <div class="sm:col-span-2">
      <label class="block text-xs font-semibold ink-dim mb-1.5">
        KRA PIN number
      </label>
      <input
        type="text"
        name="kra_pin"
        value={@form_data["kra_pin"]}
        placeholder="e.g. A012345678X"
        class="field-input w-full uppercase rounded-lg px-4 py-2.5 text-sm"
      />
    </div>

    <!-- Front Upload -->
    <div>
      <label class="block text-xs font-semibold ink-dim mb-1.5">
        {if @form_data["entity_type"] == "company",
          do: "Registration certificate",
          else: "ID — front"}
      </label>
      <div class="file-drop rounded-lg p-3.5 relative hover:border-accent transition">
        <.live_file_input
          upload={@uploads.id_front}
          class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
        />

        <%= if not Enum.empty?(@uploads.id_front.entries) do %>
          <%= for entry <- @uploads.id_front.entries do %>
            <div class="flex items-center justify-between gap-2 z-20 relative">
              <span class="text-xs font-medium ink truncate">
                {entry.client_name}
              </span>
              <button
                type="button"
                phx-click="cancel_upload"
                phx-value-ref={entry.ref}
                phx-value-upload="id_front"
                class="text-xs text-danger font-semibold hover:underline"
              >
                Remove
              </button>
            </div>
          <% end %>
        <% else %>
          <%= if @form_data["id_front_url"] && @form_data["id_front_url"] != "" do %>
            <div class="flex items-center justify-between gap-2 z-20 relative">
              <div class="flex items-center gap-2 min-w-0 pointer-events-none">
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
                  <path d="M20 6 9 17l-5-5" />
                </svg>
                <span class="text-xs font-medium ink truncate">
                  Document attached
                </span>
              </div>
              <a
                href={@form_data["id_front_url"]}
                target="_blank"
                rel="noopener noreferrer"
                class="text-xs text-accent font-semibold hover:underline pointer-events-auto"
              >
                View
              </a>
            </div>
          <% else %>
            <div class="flex items-center gap-3 pointer-events-none">
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
                <path d="M12 16V4M12 4 7 9M12 4l5 5" />
                <path d="M20 16v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-3" />
              </svg>
              <span class="min-w-0 break-words text-xs ink-dim">
                Upload photo or scan
              </span>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>

    <!-- Back Upload -->
    <div>
      <label class="block text-xs font-semibold ink-dim mb-1.5">
        {if @form_data["entity_type"] == "company",
          do: "CR12 / Tax cert",
          else: "ID — back"}
      </label>
      <div class="file-drop rounded-lg p-3.5 relative hover:border-accent transition">
        <.live_file_input
          upload={@uploads.id_back}
          class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
        />

        <%= cond do %>
          <% not Enum.empty?(@uploads.id_back.entries) -> %>
            <%= for entry <- @uploads.id_back.entries do %>
              <div class="flex items-center justify-between gap-2 z-20 relative">
                <span class="text-xs font-medium ink truncate">
                  {entry.client_name}
                </span>
                <button
                  type="button"
                  phx-click="cancel_upload"
                  phx-value-ref={entry.ref}
                  phx-value-upload="id_back"
                  class="text-xs text-danger font-semibold hover:underline"
                >
                  Remove
                </button>
              </div>
            <% end %>
          <% @form_data["id_back_url"] && @form_data["id_back_url"] != "" -> %>
            <div class="flex items-center justify-between gap-2 z-20 relative">
              <div class="flex items-center gap-2 min-w-0 pointer-events-none">
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
                  <path d="M20 6 9 17l-5-5" />
                </svg>
                <span class="text-xs font-medium ink truncate">
                  Document attached
                </span>
              </div>
              <a
                href={@form_data["id_back_url"]}
                target="_blank"
                rel="noopener noreferrer"
                class="text-xs text-accent font-semibold hover:underline pointer-events-auto"
              >
                View
              </a>
            </div>
          <% true -> %>
            <div class="flex items-center gap-3">
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
            </div>
        <% end %>
      </div>
    </div>

    <!-- KRA Certificate Upload (Full Width) -->
    <div class="sm:col-span-2">
      <label class="block text-xs font-semibold ink-dim mb-1.5">
        KRA Certificate / PIN document
      </label>
      <div class="file-drop rounded-lg p-3.5 relative hover:border-accent transition">
        <.live_file_input
          upload={@uploads.kra_doc}
          class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
        />

        <%= if not Enum.empty?(@uploads.kra_doc.entries) do %>
          <%= for entry <- @uploads.kra_doc.entries do %>
            <div class="flex items-center justify-between gap-2 z-20 relative">
              <span class="text-xs font-medium ink truncate">
                {entry.client_name}
              </span>
              <button
                type="button"
                phx-click="cancel_upload"
                phx-value-ref={entry.ref}
                phx-value-upload="kra_doc"
                class="text-xs text-danger font-semibold hover:underline"
              >
                Remove
              </button>
            </div>
          <% end %>
        <% else %>
          <%= if @form_data["kra_doc_url"] && @form_data["kra_doc_url"] != "" do %>
            <div class="flex items-center justify-between gap-2 z-20 relative">
              <div class="flex items-center gap-2 min-w-0 pointer-events-none">
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
                  <path d="M20 6 9 17l-5-5" />
                </svg>
                <span class="text-xs font-medium ink truncate">
                  Document attached
                </span>
              </div>
              <a
                href={@form_data["kra_doc_url"]}
                target="_blank"
                rel="noopener noreferrer"
                class="text-xs text-accent font-semibold hover:underline pointer-events-auto"
              >
                View
              </a>
            </div>
          <% else %>
            <div class="flex items-center gap-3 pointer-events-none">
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
                <path d="M12 16V4M12 4 7 9M12 4l5 5" />
                <path d="M20 16v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-3" />
              </svg>
              <span class="min-w-0 break-words text-xs ink-dim">
                Upload photo or scan of KRA Certificate
              </span>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
  </div>
</section>

    <!-- STEP 3 -->

                        <section class={if @step == 3, do: "block", else: "hidden"}>
                          <h2 class="font-serif-display text-lg ink mb-1">
                            Proof of ownership & property details
                          </h2>
                          <p class="ink-dim text-sm mb-5">
                            Provide details about your property portfolio and legal ownership documents.
                          </p>
                          <div class="grid sm:grid-cols-2 gap-4">
                            <!-- Listing Purpose -->
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Primary intent for listings
                              </label>
                              <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
                                <label class="flex items-center gap-2 border border-token rounded-lg p-3 cursor-pointer panel-alt">
                                  <input
                                    type="radio"
                                    name="listing_purpose"
                                    value="renting"
                                    checked={@form_data["listing_purpose"] == "renting"}
                                    class="text-accent"
                                  />
                                  <span class="text-xs font-medium ink">Renting</span>
                                </label>
                                <label class="flex items-center gap-2 border border-token rounded-lg p-3 cursor-pointer panel-alt">
                                  <input
                                    type="radio"
                                    name="listing_purpose"
                                    value="leasing"
                                    checked={@form_data["listing_purpose"] == "leasing"}
                                    class="text-accent"
                                  />
                                  <span class="text-xs font-medium ink">Leasing</span>
                                </label>
                                <label class="flex items-center gap-2 border border-token rounded-lg p-3 cursor-pointer panel-alt">
                                  <input
                                    type="radio"
                                    name="listing_purpose"
                                    value="selling"
                                    checked={@form_data["listing_purpose"] == "selling"}
                                    class="text-accent"
                                  />
                                  <span class="text-xs font-medium ink">Selling</span>
                                </label>
                                <label class="flex items-center gap-2 border border-token rounded-lg p-3 cursor-pointer panel-alt">
                                  <input
                                    type="radio"
                                    name="listing_purpose"
                                    value="mixed"
                                    checked={@form_data["listing_purpose"] == "mixed"}
                                    class="text-accent"
                                  />
                                  <span class="text-xs font-medium ink">Mixed-use</span>
                                </label>
                              </div>
                            </div>

    <!-- Property Name -->
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Property / Building name
                              </label>
                              <input
                                type="text"
                                name="property_name"
                                value={@form_data["property_name"]}
                                placeholder="e.g. Kilimani Heights, Sunrise Apartments"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>

    <!-- Property Location -->
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Exact property location
                              </label>
                              <input
                                type="text"
                                name="property_location"
                                value={@form_data["property_location"]}
                                placeholder="e.g. Kilimani, Off Argwings Kodhek Rd, Nairobi"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>

    <!-- Ownership Type -->
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

    <!-- Title Deed / LR Number -->
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

    <!-- Estimated Total Units -->
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Estimated total units on property
                              </label>
                              <input
                                type="number"
                                name="total_units"
                                min="1"
                                value={@form_data["total_units"]}
                                placeholder="e.g. 12"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>

    <!-- Ownership Document Upload -->
                            <div class="sm:col-span-2">
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Ownership document (Title Deed, Lease, or Management Agreement)
                              </label>
                              <div class="file-drop rounded-lg p-3.5 relative hover:border-accent transition">
                                <.live_file_input
                                  upload={@uploads.ownership_doc}
                                  class="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                                />

                                <%= cond do %>
                                  <% not Enum.empty?(@uploads.ownership_doc.entries) -> %>
                                    <%= for entry <- @uploads.ownership_doc.entries do %>
                                      <div class="flex items-center justify-between gap-2 z-20 relative">
                                        <div class="flex items-center gap-2 min-w-0">
                                          <svg
                                            width="16"
                                            height="16"
                                            viewBox="0 0 24 24"
                                            fill="none"
                                            stroke="currentColor"
                                            class="text-accent shrink-0"
                                            stroke-width="2"
                                            stroke-linecap="round"
                                            stroke-linejoin="round"
                                          >
                                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" />
                                          </svg>
                                          <span class="text-xs font-medium ink truncate">
                                            {entry.client_name}
                                          </span>
                                        </div>
                                        <button
                                          type="button"
                                          phx-click="cancel_upload"
                                          phx-value-ref={entry.ref}
                                          phx-value-upload="ownership_doc"
                                          class="text-xs text-danger font-semibold hover:underline shrink-0"
                                        >
                                          Remove
                                        </button>
                                      </div>
                                    <% end %>
                                  <% @form_data["ownership_doc_url"] && @form_data["ownership_doc_url"] != "" -> %>
                                    <div class="flex items-center justify-between gap-2 z-20 relative">
                                      <div class="flex items-center gap-2 min-w-0 pointer-events-none">
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
                                          <path d="M20 6 9 17l-5-5" />
                                        </svg>
                                        <span class="text-xs font-medium ink truncate">
                                          Document attached
                                        </span>
                                      </div>
                                      <a
                                        href={@form_data["ownership_doc_url"]}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        class="text-xs text-accent font-semibold hover:underline pointer-events-auto"
                                      >
                                        View
                                      </a>
                                    </div>
                                  <% true -> %>
                                    <div class="flex items-center gap-3">
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
                                        Upload PDF, JPG, or PNG document
                                      </span>
                                    </div>
                                <% end %>
                              </div>
                            </div>
                          </div>
                        </section>

    <!-- STEP 4 -->

                        <section class={if @step == 4, do: "block", else: "hidden"}>
                          <h2 class="font-serif-display text-lg ink mb-1">
                            Payment & billing preferences
                          </h2>
                          <p class="ink-dim text-sm mb-5">
                            Select your preferred payment methods for platform fees and optional payouts.
                          </p>

                          <div class="grid sm:grid-cols-2 gap-4">
                            <!-- Preferred Billing Method -->
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Preferred billing method
                              </label>
                              <select
                                name="billing_method"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              >
                                <option selected={@form_data["billing_method"] == "M-Pesa"}>
                                  M-Pesa Express
                                </option>
                                <option selected={@form_data["billing_method"] == "Card"}>
                                  Credit / Debit Card
                                </option>
                                <option selected={@form_data["billing_method"] == "Bank Transfer"}>
                                  Direct Bank Transfer
                                </option>
                              </select>
                            </div>

    <!-- Billing Phone Number -->
                            <div>
                              <label class="block text-xs font-semibold ink-dim mb-1.5">
                                Billing phone number (for M-Pesa STK push)
                              </label>
                              <input
                                type="tel"
                                name="billing_phone"
                                value={@form_data["billing_phone"]}
                                placeholder="07XX XXX XXX"
                                class="field-input w-full rounded-lg px-4 py-2.5 text-sm"
                              />
                            </div>

    <!-- Optional Direct Payouts Section -->
                            <div class="sm:col-span-2 mt-2 pt-4 border-t border-token">
                              <div class="flex items-center gap-2 mb-3">
                                <input
                                  type="checkbox"
                                  name="enable_payouts"
                                  id="enable_payouts"
                                  checked={
                                    @form_data["enable_payouts"] == true or
                                      @form_data["enable_payouts"] == "true"
                                  }
                                  class="rounded text-accent"
                                />
                                <label
                                  for="enable_payouts"
                                  class="text-xs font-semibold ink cursor-pointer"
                                >
                                  Add payout account details (For receiving proceeds or direct rent collection)
                                </label>
                              </div>

                              <%= if @form_data["enable_payouts"] == true or @form_data["enable_payouts"] == "true" do %>
                                <div class="grid sm:grid-cols-3 gap-3 p-3.5 rounded-lg panel-alt border border-token">
                                  <div>
                                    <label class="block text-xs font-semibold ink-dim mb-1">
                                      Payout channel
                                    </label>
                                    <select
                                      name="payout_method"
                                      class="field-input w-full rounded-lg px-3 py-2 text-xs"
                                    >
                                      <option selected={@form_data["payout_method"] == "M-Pesa"}>
                                        M-Pesa
                                      </option>
                                      <option selected={@form_data["payout_method"] == "Bank Account"}>
                                        Bank Account
                                      </option>
                                    </select>
                                  </div>
                                  <div>
                                    <label class="block text-xs font-semibold ink-dim mb-1">
                                      Account / Phone number
                                    </label>
                                    <input
                                      type="text"
                                      name="payout_number"
                                      value={@form_data["payout_number"]}
                                      placeholder="e.g. 07XX XXX XXX or account no."
                                      class="field-input w-full rounded-lg px-3 py-2 text-xs"
                                    />
                                  </div>
                                  <div>
                                    <label class="block text-xs font-semibold ink-dim mb-1">
                                      Account holder name
                                    </label>
                                    <input
                                      type="text"
                                      name="payout_name"
                                      value={@form_data["payout_name"]}
                                      placeholder="e.g. John Doe"
                                      class="field-input w-full rounded-lg px-3 py-2 text-xs"
                                    />
                                  </div>
                                </div>
                              <% end %>
                            </div>
                          </div>
                        </section>

    <!-- STEP 5 --><!-- STEP 5 -->
                        <section class={if @step == 5, do: "block", else: "hidden"}>
                          <h2 class="font-serif-display text-lg ink mb-1">Review & submit</h2>
                          <p class="ink-dim text-sm mb-5">
                            Please review your information before completing registration.
                          </p>

                          <div class="space-y-4 text-xs">
                            <!-- Step 1 Summary -->
                            <div class="panel-alt border border-token rounded-lg p-4">
                              <div class="flex items-center justify-between mb-2">
                                <h3 class="font-semibold ink text-sm">1. Personal details</h3>
                                <button
                                  type="button"
                                  phx-click="go_to_step"
                                  phx-value-step="1"
                                  class="text-accent hover:underline font-medium"
                                >
                                  Edit
                                </button>
                              </div>
                              <div class="grid grid-cols-2 gap-2 ink-dim">
                                <div>
                                  <span class="font-medium ink">Category:</span> {String.capitalize(
                                    @form_data["entity_type"] || "individual"
                                  )} Landlord
                                </div>
                                <div>
                                  <span class="font-medium ink">Name:</span> {@form_data["names"]}
                                </div>
                                <div>
                                  <span class="font-medium ink">Email:</span> {@form_data["email"]}
                                </div>
                                <div>
                                  <span class="font-medium ink">Phone:</span> {@form_data["phone"]}
                                </div>
                                <div>
                                  <span class="font-medium ink">WhatsApp:</span> {@form_data[
                                    "whatsapp_phone"
                                  ]}
                                </div>
                                <div>
                                  <span class="font-medium ink">Residence:</span> {@form_data[
                                    "residence_location"
                                  ]}
                                </div>
                              </div>
                            </div>

    <!-- Step 2 Summary -->
                            <div class="panel-alt border border-token rounded-lg p-4">
                              <div class="flex items-center justify-between mb-2">
                                <h3 class="font-semibold ink text-sm">2. Identity verification</h3>
                                <button
                                  type="button"
                                  phx-click="go_to_step"
                                  phx-value-step="2"
                                  class="text-accent hover:underline font-medium"
                                >
                                  Edit
                                </button>
                              </div>
                              <div class="grid grid-cols-2 gap-2 ink-dim">
                                <div>
                                  <span class="font-medium ink">Doc type:</span> {@form_data[
                                    "id_type"
                                  ]}
                                </div>
                                <div>
                                  <span class="font-medium ink">Doc / ID no:</span> {@form_data[
                                    "id_number"
                                  ]}
                                </div>
                                <div>
                                  <span class="font-medium ink">KRA PIN:</span> {String.upcase(
                                    @form_data["kra_pin"] || ""
                                  )}
                                </div>
                                <div>
                                  <span class="font-medium ink">Uploads:</span>
                                  {if Enum.empty?(@uploads.id_front.entries),
                                    do: "Front missing",
                                    else: "Front attached"}, {if Enum.empty?(
                                                                   @uploads.id_back.entries
                                                                 ),
                                                                 do: "Back missing",
                                                                 else: "Back attached"}
                                </div>
                              </div>
                            </div>

    <!-- Step 3 Summary -->
                            <div class="panel-alt border border-token rounded-lg p-4">
                              <div class="flex items-center justify-between mb-2">
                                <h3 class="font-semibold ink text-sm">3. Property details</h3>
                                <button
                                  type="button"
                                  phx-click="go_to_step"
                                  phx-value-step="3"
                                  class="text-accent hover:underline font-medium"
                                >
                                  Edit
                                </button>
                              </div>
                              <div class="grid grid-cols-2 gap-2 ink-dim">
                                <div>
                                  <span class="font-medium ink">Intent:</span> {String.capitalize(
                                    @form_data["listing_purpose"] || "renting"
                                  )}
                                </div>
                                <div>
                                  <span class="font-medium ink">Property name:</span> {@form_data[
                                    "property_name"
                                  ]}
                                </div>
                                <div>
                                  <span class="font-medium ink">Location:</span> {@form_data[
                                    "property_location"
                                  ]}
                                </div>
                                <div>
                                  <span class="font-medium ink">Ownership type:</span> {@form_data[
                                    "ownership_type"
                                  ]}
                                </div>
                                <div>
                                  <span class="font-medium ink">Title / LR no:</span> {@form_data[
                                    "lr_number"
                                  ]}
                                </div>
                                <div>
                                  <span class="font-medium ink">Total units:</span> {@form_data[
                                    "total_units"
                                  ]}
                                </div>
                                <div>
                                  <span class="font-medium ink">Ownership doc:</span>
                                  {if Enum.empty?(@uploads.ownership_doc.entries) and
                                      (@form_data["ownership_doc_url"] in [nil, ""]),
                                    do: "Not uploaded",
                                    else: "Attached"}
                                </div>
                              </div>
                            </div>

    <!-- Step 4 Summary -->
                            <div class="panel-alt border border-token rounded-lg p-4">
                              <div class="flex items-center justify-between mb-2">
                                <h3 class="font-semibold ink text-sm">4. Billing & payment</h3>
                                <button
                                  type="button"
                                  phx-click="go_to_step"
                                  phx-value-step="4"
                                  class="text-accent hover:underline font-medium"
                                >
                                  Edit
                                </button>
                              </div>
                              <div class="grid grid-cols-2 gap-2 ink-dim">
                                <div>
                                  <span class="font-medium ink">Billing method:</span> {@form_data[
                                    "billing_method"
                                  ]}
                                </div>
                                <div>
                                  <span class="font-medium ink">Billing phone:</span> {@form_data[
                                    "billing_phone"
                                  ]}
                                </div>
                                <%= if @form_data["enable_payouts"] == true or @form_data["enable_payouts"] == "true" do %>
                                  <div>
                                    <span class="font-medium ink">Payout method:</span> {@form_data[
                                      "payout_method"
                                    ]}
                                  </div>
                                  <div>
                                    <span class="font-medium ink">Payout details:</span> {@form_data[
                                      "payout_number"
                                    ]} ({@form_data["payout_name"]})
                                  </div>
                                <% end %>
                              </div>
                            </div>

    <!-- Compliance Terms Checkbox -->
                            <div class="pt-2">
                              <label class="flex items-start gap-2.5 cursor-pointer">
                                <input
                                  type="checkbox"
                                  name="comply"
                                  checked={
                                    @form_data["comply"] == true or @form_data["comply"] == "true"
                                  }
                                  required
                                  class="mt-0.5 rounded text-accent"
                                />
                                <span class="text-xs ink-dim leading-normal">
                                  I confirm that all details and documents provided are accurate and legally valid. I accept the
                                  <a href="#" class="text-accent underline">Terms of Service</a>
                                  and <a href="#" class="text-accent underline">Privacy Policy</a>.
                                </span>
                              </label>
                            </div>
                          </div>
                        </section>
                      </form>
                    </main>
                  </div>

    <!-- Footer Navigation -->
                  <div class="px-4 sm:px-8 py-4 border-t border-token flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                    <button
                      type="button"
                      phx-click="save_draft"
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
