defmodule HomeWeb.Admin.DashboardLive do
  use HomeWeb, :live_view
  alias Home.Repo
  alias Home.Properties.Property
  alias Home.Bookings.Booking
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_tab, "add_property")
      |> assign(:mobile_menu_open, false)
      |> assign(:editing_property_id, nil)
      |> assign(:form_data, default_form_data())
      |> fetch_database_records()
      |> allow_upload(:property_images, accept: ~w(.jpg .jpeg .png), max_entries: 5)

    {:ok, socket}
  end

  defp default_form_data do
    %{
      "title" => "",
      "location" => "",
      "night_price" => "",
      "day_price" => "",
      "tier" => "Normal",
      "wifi" => "false",
      "tv" => "false",
      "music_system" => "false",
      "status" => "Available",
      "unavailable_until" => ""
    }
  end

  defp fetch_database_records(socket) do
    properties = Property |> order_by(desc: :id) |> Repo.all() |> Repo.preload(:property_images)
    bookings = Booking |> order_by(desc: :inserted_at) |> Repo.all() |> Repo.preload(:property)
    assign(socket, properties: properties, bookings: bookings)
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply,
     assign(socket, current_tab: tab, editing_property_id: nil, mobile_menu_open: false)}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _, socket) do
    {:noreply, assign(socket, mobile_menu_open: !socket.assigns.mobile_menu_open)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :property_images, ref)}
  end

  # dedicated, reliable toggle for the perk buttons (wifi / tv / music_system).
  # This is independent of the surrounding form's phx-change, so clicking always
  # flips the value instantly - no more relying on the browser silently omitting
  # unchecked checkboxes from the submitted params.
  @impl true
  def handle_event("toggle_feature", %{"feature" => feature}, socket)
      when feature in ["wifi", "tv", "music_system"] do
    current_value = Map.get(socket.assigns.form_data, feature, "false")
    new_value = if current_value == "true", do: "false", else: "true"

    {:noreply, assign(socket, form_data: Map.put(socket.assigns.form_data, feature, new_value))}
  end

  @impl true
  def handle_event("change_form", %{"property" => property_params}, socket) do
    features_normalized = %{
      "wifi" => Map.get(property_params, "wifi", "false"),
      "tv" => Map.get(property_params, "tv", "false"),
      "music_system" => Map.get(property_params, "music_system", "false")
    }

    normalized = Map.merge(property_params, features_normalized)

    {:noreply, assign(socket, form_data: normalized)}
  end

  def handle_event("change_form", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_property", %{"property" => params}, socket) do
    upload_results =
      consume_uploaded_entries(socket, :property_images, fn %{path: path}, _entry ->
        # consume_uploaded_entries deletes the tmp file right after this callback
        # returns, so we upload to Cloudinary synchronously from the tmp path.
        {:ok, Home.Cloudinary.upload(path)}
      end)

    {uploaded_urls, upload_errors} =
      Enum.split_with(upload_results, &match?({:ok, _url}, &1))

    uploaded_urls = Enum.map(uploaded_urls, fn {:ok, url} -> url end)

    if upload_errors != [] do
      Enum.each(upload_errors, fn {:error, reason} ->
        require Logger
        Logger.error("Cloudinary upload failed: #{inspect(reason)}")
      end)
    end

    unavailable_until_raw = Map.get(params, "unavailable_until", "")

    unavailable_until_parsed =
      if params["status"] != "Available" and unavailable_until_raw != "" do
        if String.length(unavailable_until_raw) == 16,
          do: unavailable_until_raw <> ":00",
          else: unavailable_until_raw
      else
        nil
      end

    property_changeset =
      Property.changeset(%Property{}, %{
        title: params["title"],
        location: params["location"],
        night_price: String.to_integer(params["night_price"] || "0"),
        day_price: String.to_integer(params["day_price"] || "0"),
        tier: params["tier"] || "Normal",
        wifi: params["wifi"] == "true",
        tv: params["tv"] == "true",
        music_system: params["music_system"] == "true",
        status: params["status"] || "Available",
        unavailable_until: unavailable_until_parsed
      })

    case Repo.transaction(fn ->
           with {:ok, saved} <- Repo.insert(property_changeset) do
             Enum.each(
               uploaded_urls,
               &Repo.insert!(%Home.Properties.PropertyImage{property_id: saved.id, image_url: &1})
             )

             saved
           else
             {:error, cs} -> Repo.rollback(cs)
           end
         end) do
      {:ok, _} ->
        flash_kind = if upload_errors == [], do: :info, else: :error

        flash_message =
          if upload_errors == [] do
            "Property saved successfully."
          else
            "Property saved, but #{length(upload_errors)} image(s) failed to upload to Cloudinary."
          end

        {:noreply,
         socket
         |> put_flash(flash_kind, flash_message)
         |> assign(:form_data, default_form_data())
         |> fetch_database_records()
         |> assign(:current_tab, "manage_properties")}

      _ ->
        {:noreply, put_flash(socket, :error, "Error saving records.")}
    end
  end

  @impl true
  def handle_event("delete_property", %{"id" => id}, socket) do
    Property |> Repo.get!(String.to_integer(id)) |> Repo.delete!()
    {:noreply, socket |> put_flash(:info, "Item removed.") |> fetch_database_records()}
  end

  defp fill_blank(val, fallback) do
    if val in ["", nil], do: fallback, else: val
  end

  @impl true
  def render(assigns) do
    lnk =
      "w-full flex items-center justify-between px-4 py-3 rounded-xl text-sm font-medium transition-all "

    act = "bg-blue-600 text-white shadow-lg shadow-blue-600/20"
    inact = "hover:bg-zinc-800/70 text-zinc-400 hover:text-zinc-100"

    inp =
      "w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-zinc-100 focus:border-blue-500 focus:outline-none"

    prk =
      "flex flex-col items-center justify-center p-4 rounded-xl border text-center cursor-pointer select-none transition-all duration-150 "

    assigns = assign(assigns, lnk: lnk, act: act, inact: inact, inp: inp, prk: prk)

    ~H"""
    <div class="flex flex-col lg:flex-row min-h-screen bg-zinc-950 text-zinc-100 font-sans antialiased">
      <header class="bg-zinc-900 border-b border-zinc-800 px-5 py-4 flex lg:hidden justify-between items-center sticky top-0 z-40">
        <h1 class="text-base font-bold text-white flex items-center gap-2">
          <svg class="w-5 h-5 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
          </svg>
          <span>Home Admin</span>
        </h1>
        <button
          phx-click="toggle_mobile_menu"
          class="px-3 py-1.5 bg-zinc-950 rounded-xl border border-zinc-800 text-zinc-300 text-xs font-medium"
        >
          {if @mobile_menu_open, do: "✕ Close", else: "☰ Menu"}
        </button>
      </header>

      <aside class={"fixed inset-y-0 left-0 w-64 bg-zinc-900 border-r border-zinc-800 flex flex-col justify-between transform transition-transform duration-300 ease-in-out z-30 lg:translate-x-0 lg:static lg:h-screen #{if @mobile_menu_open, do: "translate-x-0 pt-16 lg:pt-0", else: "-translate-x-full"}"}>
        <div>
          <div class="hidden lg:flex p-6 border-b border-zinc-800/60">
            <h1 class="text-xl font-bold text-white flex items-center gap-2">
              <svg class="w-6 h-6 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              <span>Home Admin</span>
            </h1>
          </div>
          <nav class="p-4 space-y-1.5">
            <.link
              navigate={~p"/admin"}
              class={@lnk <> if(@current_tab == "add_property", do: @act, else: @inact)}
            >
              <span class="flex items-center gap-3">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                </svg>
                <span>Add New Unit</span>
              </span>
            </.link>
            <.link
              navigate={~p"/admin/property"}
              class={@lnk <> if(@current_tab == "manage_properties", do: @act, else: @inact)}
            >
              <span class="flex items-center gap-3">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 10h16M4 14h16M4 18h16" />
                </svg>
                <span>View Your Houses</span>
              </span>
            </.link>
            <.link
              navigate={~p"/admin/bookings"}
              class={@lnk <> if(@current_tab == "bookings", do: @act, else: @inact)}
            >
              <span class="flex items-center gap-3">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 002-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <span>Client Bookings</span>
              </span>
              <span class="bg-zinc-950/60 text-blue-400 font-bold px-2 py-0.5 rounded-md text-[11px] border border-zinc-800">
                {length(@bookings)}
              </span>
            </.link>
            <div
              role="button"
              class="w-full flex items-center justify-between px-4 py-3 rounded-xl text-sm font-medium transition-all text-zinc-500 bg-zinc-950/20 border border-zinc-900/50 cursor-not-allowed select-none"
            >
              <span class="flex items-center gap-3">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                </svg>
                <span>Messages</span>
              </span>
              <span class="bg-zinc-800 text-zinc-500 font-semibold px-1.5 py-0.5 rounded text-[10px]">
                Soon
              </span>
            </div>
            <.link
              navigate={~p"/admin/notifications"}
              class={@lnk <> if(@current_tab == "notifications", do: @act, else: @inact)}
            >
              <span class="flex items-center gap-3">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
                <span>Notifications</span>
              </span>
              <span class="bg-zinc-800 text-blue-400 font-semibold px-1.5 py-0.5 rounded text-[10px]">
                Soon
              </span>
            </.link>
          </nav>
        </div>
      </aside>

      <main class="flex-1 flex flex-col lg:h-screen lg:overflow-y-auto">
        <header class="bg-zinc-900/40 border-b border-zinc-800 px-8 py-4 hidden lg:flex justify-between items-center">
          <h2 class="text-sm font-medium uppercase tracking-wider text-zinc-400">
            {@current_tab |> String.replace("_", " ")} View
          </h2>
          <span class="text-xs font-semibold text-blue-400 bg-blue-500/10 border border-blue-500/20 px-3 py-1 rounded-full">
            Live Database Stack
          </span>
        </header>

        <div class="p-4 md:p-8 max-w-7xl w-full mx-auto">
          <%= if @current_tab == "add_property" do %>
            <div class="grid grid-cols-1 xl:grid-cols-12 gap-8 items-start">
              <div class="xl:col-span-7 bg-zinc-900/60 border border-zinc-800 p-5 md:p-6 rounded-2xl">
                <form phx-change="change_form" phx-submit="save_property" class="space-y-5">
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">
                        House Title
                      </label>
                      <input
                        type="text"
                        name="property[title]"
                        value={@form_data["title"]}
                        placeholder="e.g., Sunrise Penthouse"
                        required
                        class={@inp}
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">
                        Location
                      </label>
                      <input
                        type="text"
                        name="property[location]"
                        value={@form_data["location"]}
                        placeholder="e.g., Kilimani, Nairobi"
                        required
                        class={@inp}
                      />
                    </div>
                  </div>
                  <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">
                        Night Price (KES)
                      </label>
                      <input
                        type="number"
                        name="property[night_price]"
                        value={@form_data["night_price"]}
                        placeholder="4500"
                        required
                        class={@inp}
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">
                        Day Price (KES)
                      </label>
                      <input
                        type="number"
                        name="property[day_price]"
                        value={@form_data["day_price"]}
                        placeholder="2500"
                        class={@inp}
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">
                        Tier
                      </label>
                      <select name="property[tier]" class={@inp}>
                        <option value="Normal" selected={@form_data["tier"] == "Normal"}>
                          Normal
                        </option>
                        <option value="Medium" selected={@form_data["tier"] == "Medium"}>
                          Medium
                        </option>
                        <option value="Premium" selected={@form_data["tier"] == "Premium"}>
                          Premium
                        </option>
                      </select>
                    </div>
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-zinc-400 mb-2 uppercase tracking-wider">
                      Included Perks
                    </label>
                    <div class="grid grid-cols-3 gap-3">
                      <!--
                        Perks are now driven by phx-click (independent, instant toggle)
                        instead of a raw checkbox tied into the form's phx-change.
                        A hidden input keeps the current value in sync for save_property.
                      -->
                      <input type="hidden" name="property[wifi]" value={@form_data["wifi"]} />
                      <div
                        role="button"
                        tabindex="0"
                        phx-click="toggle_feature"
                        phx-value-feature="wifi"
                        class={@prk <> if(@form_data["wifi"] == "true", do: "border-blue-500 bg-blue-500/10 text-blue-400", else: "border-zinc-800 bg-zinc-950/20 text-zinc-500 hover:border-zinc-700")}
                      >
                        <svg class="w-5 h-5 mb-1.5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M8.284 16.284A3 3 0 0012 17a3 3 0 003.716-.716M5.456 13.456a7 7 0 019.088 0M2.628 10.628a11 11 0 0114.744 0M12 21v-1.5" />
                        </svg>
                        <span class="text-xs font-medium tracking-wide">WiFi Access</span>
                      </div>

                      <input type="hidden" name="property[tv]" value={@form_data["tv"]} />
                      <div
                        role="button"
                        tabindex="0"
                        phx-click="toggle_feature"
                        phx-value-feature="tv"
                        class={@prk <> if(@form_data["tv"] == "true", do: "border-blue-500 bg-blue-500/10 text-blue-400", else: "border-zinc-800 bg-zinc-950/20 text-zinc-500 hover:border-zinc-700")}
                      >
                        <svg class="w-5 h-5 mb-1.5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M6 20.25h12m-7.5-3v3m3-3v3m-10.125-3h17.25c.621 0 1.125-.504 1.125-1.125V4.875c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125z" />
                        </svg>
                        <span class="text-xs font-medium tracking-wide">Smart TV</span>
                      </div>

                      <input type="hidden" name="property[music_system]" value={@form_data["music_system"]} />
                      <div
                        role="button"
                        tabindex="0"
                        phx-click="toggle_feature"
                        phx-value-feature="music_system"
                        class={@prk <> if(@form_data["music_system"] == "true", do: "border-blue-500 bg-blue-500/10 text-blue-400", else: "border-zinc-800 bg-zinc-950/20 text-zinc-500 hover:border-zinc-700")}
                      >
                        <svg class="w-5 h-5 mb-1.5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M19.114 5.636a9 9 0 010 12.728M16.463 8.288a5.25 5.25 0 010 7.424M6.75 8.25l4.72-4.72a.75.75 0 011.28.53v15.88a.75.75 0 01-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.01 9.01 0 012.25 12c0-.83.112-1.633.322-2.396C2.806 8.756 3.63 8.25 4.51 8.25H6.75z" />
                        </svg>
                        <span class="text-xs font-medium tracking-wide">Sound Stack</span>
                      </div>
                    </div>
                  </div>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">
                        Status
                      </label>
                      <select name="property[status]" class={@inp}>
                        <option value="Available" selected={@form_data["status"] == "Available"}>
                          Available
                        </option>
                        <option value="Occupied" selected={@form_data["status"] == "Occupied"}>
                          Occupied
                        </option>
                        <option value="Maintenance" selected={@form_data["status"] == "Maintenance"}>
                          Maintenance
                        </option>
                      </select>
                    </div>
                    <%= if @form_data["status"] != "Available" do %>
                      <div>
                        <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">
                          Unavailable Till
                        </label>
                        <input
                          type="datetime-local"
                          name="property[unavailable_until]"
                          value={@form_data["unavailable_until"]}
                          style="color-scheme: dark;"
                          required
                          class={@inp <> " cursor-pointer"}
                        />
                      </div>
                    <% end %>
                  </div>
                  <div>
                    <label
                      class="block border border-dashed border-zinc-800 p-6 rounded-xl text-center bg-zinc-950/20 hover:border-zinc-700 transition-all cursor-pointer select-none"
                      phx-drop-target={@uploads.property_images.ref}
                    >
                      <.live_file_input
                        upload={@uploads.property_images}
                        class="hidden"
                      />
                      <span class="text-xs font-semibold text-blue-400 block py-4">
                        📂 Click here or drag files to select unit photos
                      </span>
                    </label>
                  </div>
                  <button
                    type="submit"
                    class="w-full bg-blue-600 hover:bg-blue-500 py-3 rounded-xl font-medium transition-all shadow-lg shadow-blue-600/10"
                  >
                    Post
                  </button>
                </form>
              </div>

              <div class="xl:col-span-5 lg:sticky lg:top-6 space-y-4">
                <h3 class="text-xs font-bold uppercase tracking-widest text-zinc-500 flex items-center gap-2 px-1">
                  <span class="w-2 h-2 rounded-full bg-blue-500 animate-pulse"></span>
                  Dynamic Card Preview
                </h3>
                <div class="bg-zinc-900 border border-zinc-800 rounded-3xl overflow-hidden shadow-2xl">
                  <div class="relative h-52 bg-zinc-950 flex items-center justify-center overflow-hidden">
                    <%= if Enum.any?(@uploads.property_images.entries) do %>
                      <%= for entry <- Enum.take(@uploads.property_images.entries, 1) do %>
                        <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                      <% end %>
                    <% else %>
                      <div class="absolute inset-0 flex items-center justify-center text-xs text-zinc-600 font-medium">
                        Staged Gallery Empty
                      </div>
                    <% end %>
                    <div class="absolute top-4 left-4 flex gap-1.5">
                      <span class="bg-zinc-900/90 text-zinc-300 text-[10px] font-bold tracking-wider uppercase px-2 py-0.5 rounded-md border border-zinc-800">
                        {@form_data["tier"]}
                      </span>
                      <span class={"text-[10px] font-bold tracking-wider uppercase px-2 py-0.5 rounded-md border #{if @form_data["status"] == "Available", do: "bg-green-500/20 border-green-500/30 text-green-400", else: "bg-amber-500/20 border-amber-500/30 text-amber-400"}"}>
                        {@form_data["status"]}
                      </span>
                    </div>
                    <div class="absolute top-4 right-4 bg-zinc-900/90 text-xs font-semibold px-2.5 py-1 rounded-full border border-zinc-800">
                      KES {@form_data["night_price"] |> fill_blank("0")}/night
                    </div>
                  </div>

                  <%= if Enum.any?(@uploads.property_images.entries) do %>
                    <div class="p-3 bg-zinc-950/60 border-b border-zinc-800 flex gap-2 overflow-x-auto scrollbar-none shadow-inner">
                      <%= for entry <- @uploads.property_images.entries do %>
                        <div class="relative w-16 h-16 rounded-lg overflow-hidden border border-zinc-800 flex-shrink-0 group">
                          <.live_img_preview
                            entry={entry}
                            class="w-full h-full object-cover transition-transform duration-200 group-hover:scale-105"
                          />
                          <button
                            type="button"
                            phx-click="cancel-upload"
                            phx-value-ref={entry.ref}
                            class="absolute top-0 right-0 bg-red-600/90 text-white font-bold p-1 rounded-bl text-[9px] transition-opacity opacity-0 group-hover:opacity-100"
                          >
                            ✕
                          </button>
                        </div>
                      <% end %>
                    </div>
                  <% end %>

                  <div class="p-5 space-y-4">
                    <div>
                      <h4 class="text-xl font-bold text-white truncate">
                        {@form_data["title"] |> fill_blank("Untitled Property")}
                      </h4>
                      <p class="text-zinc-400 text-sm mt-1 flex items-center gap-1">
                        <svg class="w-3.5 h-3.5 text-zinc-500" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                          <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                        <span>{@form_data["location"] |> fill_blank("Location unassigned")}</span>
                      </p>
                    </div>
                    <div class="flex flex-wrap gap-1.5">
                      <%= if @form_data["wifi"] == "true" do %>
                        <span class="bg-zinc-950 text-zinc-400 text-[10px] px-2 py-1 rounded-md border border-zinc-800 flex items-center gap-1">
                          <svg class="w-3 h-3 text-blue-400" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M8.284 16.284A3 3 0 0012 17a3 3 0 003.716-.716M5.456 13.456a7 7 0 019.088 0M2.628 10.628a11 11 0 0114.744 0M12 21v-1.5" />
                          </svg>
                          <span>WiFi Access</span>
                        </span>
                      <% end %>
                      <%= if @form_data["tv"] == "true" do %>
                        <span class="bg-zinc-950 text-zinc-400 text-[10px] px-2 py-1 rounded-md border border-zinc-800 flex items-center gap-1">
                          <svg class="w-3 h-3 text-blue-400" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M6 20.25h12m-7.5-3v3m3-3v3m-10.125-3h17.25c.621 0 1.125-.504 1.125-1.125V4.875c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125z" />
                          </svg>
                          <span>Smart TV</span>
                        </span>
                      <% end %>
                      <%= if @form_data["music_system"] == "true" do %>
                        <span class="bg-zinc-950 text-zinc-400 text-[10px] px-2 py-1 rounded-md border border-zinc-800 flex items-center gap-1">
                          <svg class="w-3 h-3 text-blue-400" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19.114 5.636a9 9 0 010 12.728M16.463 8.288a5.25 5.25 0 010 7.424M6.75 8.25l4.72-4.72a.75.75 0 011.28.53v15.88a.75.75 0 01-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.01 9.01 0 012.25 12c0-.83.112-1.633.322-2.396C2.806 8.756 3.63 8.25 4.51 8.25H6.75z" />
                          </svg>
                          <span>Sound Stack</span>
                        </span>
                      <% end %>
                    </div>
                    <div class="text-[11px] text-zinc-500 pt-3 border-t border-zinc-800/60">
                      Day stay fee:
                      <span class="text-zinc-200">
                        KES {@form_data["day_price"] |> fill_blank("0")}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @current_tab == "manage_properties" do %>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <%= for property <- @properties do %>
                <div class="bg-zinc-900/40 border border-zinc-800 rounded-2xl overflow-hidden flex flex-col justify-between">
                  <div>
                    <div class="h-44 bg-zinc-950 overflow-hidden relative">
                      <%= if img = List.first(property.property_images) do %>
                        <img src={img.image_url} class="w-full h-full object-cover" />
                      <%= else %>
                        <div class="w-full h-full bg-zinc-900 flex items-center justify-center text-xs text-zinc-600">
                          No Image Attached
                        </div>
                      <% end %>
                      <span class="absolute top-3 left-3 bg-zinc-900/90 border border-zinc-800 text-[10px] px-2 py-0.5 rounded text-zinc-300 uppercase font-semibold">
                        {property.status}
                      </span>
                    </div>
                    <div class="p-4 space-y-2">
                      <h4 class="text-base font-bold text-white">{property.title}</h4>
                      <p class="text-xs text-zinc-500">
                        📍 {property.location} • <span class="text-blue-400">{property.tier}</span>
                      </p>
                      <div class="text-xs text-zinc-400 pt-2 border-t border-zinc-800/60">
                        Nightly: <strong>KES {property.night_price}</strong>
                        | Day: <strong>KES {property.day_price}</strong>
                      </div>
                    </div>
                  </div>
                  <div class="p-4 pt-0 flex justify-end">
                    <button
                      phx-click="delete_property"
                      phx-value-id={property.id}
                      class="text-xs text-red-400 hover:underline"
                      data-confirm="Delete permanently?"
                    >
                      Remove
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>

          <%= if @current_tab == "bookings" do %>
            <div class="bg-zinc-900/60 border border-zinc-800 rounded-2xl overflow-x-auto">
              <table class="w-full text-left border-collapse text-sm">
                <thead>
                  <tr class="border-b border-zinc-800 text-zinc-400 text-xs uppercase bg-zinc-900/80">
                    <th class="p-4">Client Detail</th>
                    <th class="p-4">Property Room</th>
                    <th class="p-4">Stay Windows</th>
                    <th class="p-4">Valuation</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-zinc-800/50">
                  <%= for booking <- @bookings do %>
                    <tr class="hover:bg-zinc-900/20 transition-all">
                      <td class="p-4">
                        <div class="font-medium text-white">{booking.client_name}</div>
                        <div class="text-xs text-zinc-500">{booking.client_phone}</div>
                      </td>
                      <td class="p-4 font-medium text-zinc-300">{booking.property.title}</td>
                      <td class="p-4 text-xs text-zinc-400">
                        📅 {booking.check_in} to {booking.check_out}
                      </td>
                      <td class="p-4 font-semibold text-white">KES {booking.total_price}</td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </main>
    </div>
    """
  end
end