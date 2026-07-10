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

  defp fetch_database_records(socket) do
    properties = 
      Property
      |> order_by(desc: :id)
      |> Repo.all()
      |> Repo.preload(:property_images)

    bookings = 
      Booking
      |> order_by(desc: :inserted_at)
      |> Repo.all()
      |> Repo.preload(:property)

    socket
    |> assign(:properties, properties)
    |> assign(:bookings, bookings)
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, current_tab: tab, editing_property_id: nil, mobile_menu_open: false)}
  end

  @impl true
  def handle_event("toggle_mobile_menu", _, socket) do
    {:noreply, assign(socket, mobile_menu_open: !socket.assigns.mobile_menu_open)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :property_images, ref)}
  end

  @impl true
  def handle_event("change_form", params, socket) do
    property_params = Map.get(params, "property", %{})

    normalized_params = 
      property_params
      |> Map.put_new("wifi", "false")
      |> Map.put_new("tv", "false")
      |> Map.put_new("music_system", "false")

    {:noreply, assign(socket, form_data: normalized_params)}
  end

  @impl true
  def handle_event("save_property", %{"property" => params}, socket) do
    # 1. Consume the uploaded images and return raw URL strings directly
    uploaded_urls =
      consume_uploaded_entries(socket, :property_images, fn %{path: path}, _entry ->
        case upload_to_cloudinary(path) do
          {:ok, url} -> url
          {:error, _reason} -> nil
        end
      end)
      |> Enum.filter(& &1)

    # Fallback placeholder if no images were attached
    image_urls = if uploaded_urls == [], do: ["https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600"], else: uploaded_urls

    # 2. Build the property changeset from form params safely
    property_changeset = Property.changeset(%Property{}, %{
      title: params["title"],
      location: params["location"],
      night_price: String.to_integer(params["night_price"] || "0"),
      day_price: String.to_integer(params["day_price"] || "0"),
      tier: params["tier"] || "Normal",
      wifi: params["wifi"] == "true",
      tv: params["tv"] == "true",
      music_system: params["music_system"] == "true",
      status: params["status"] || "Available",
      unavailable_until: if(params["status"] != "Available" and Map.get(params, "unavailable_until", "") != "", do: params["unavailable_until"], else: nil)
    })

    # 3. Open an atomic database transaction
    transaction_result = 
      Repo.transaction(fn ->
        with {:ok, saved_property} <- Repo.insert(property_changeset) do
          Enum.each(image_urls, fn url ->
            Repo.insert!(%Home.Properties.PropertyImage{
              property_id: saved_property.id, 
              image_url: url
            })
          end)
          saved_property
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)

    # 4. Handle execution outcome and refresh layout view state
    case transaction_result do
      {:ok, _property} ->
        {:noreply, 
         socket 
         |> put_flash(:info, "Property saved with assets uploaded successfully.")
         |> assign(:form_data, default_form_data())
         |> fetch_database_records()
         |> assign(:current_tab, "manage_properties")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Error committing records to production database.")}
    end
  end

  @impl true
  def handle_event("delete_property", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    property = Repo.get!(Property, id)
    Repo.delete!(property)

    {:noreply, socket |> put_flash(:info, "Item removed.") |> fetch_database_records()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col lg:flex-row min-h-screen bg-zinc-950 text-zinc-100 font-sans antialiased">
      
      <header class="bg-zinc-900 border-b border-zinc-800 px-5 py-4 flex lg:hidden justify-between items-center sticky top-0 z-40">
        <h1 class="text-base font-bold text-white flex items-center gap-2">
          <span class="text-blue-500">🏠</span> Home Admin
        </h1>
        <button phx-click="toggle_mobile_menu" class="px-3 py-1.5 bg-zinc-950 rounded-xl border border-zinc-800 text-zinc-300 hover:text-white transition-all text-xs font-medium">
          <%= if @mobile_menu_open, do: "✕ Close", else: "☰ Menu" %>
        </button>
      </header>

      <aside class={"fixed inset-y-0 left-0 w-64 bg-zinc-900 border-r border-zinc-800 flex flex-col justify-between transform transition-transform duration-300 ease-in-out z-30 lg:translate-x-0 lg:static lg:h-screen #{if @mobile_menu_open, do: "translate-x-0 pt-16 lg:pt-0", else: "-translate-x-full"}"}>
        <div>
          <div class="hidden lg:flex p-6 border-b border-zinc-800/60">
            <h1 class="text-xl font-bold text-white flex items-center gap-2"><span class="text-blue-500">🏠</span> Home Admin</h1>
          </div>
          
          <nav class="p-4 space-y-1.5">
            <.link navigate={~p"/admin"}
              class={"w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all #{if @current_tab == "add_property", do: "bg-blue-600 text-white shadow-lg shadow-blue-600/20", else: "hover:bg-zinc-800/70 text-zinc-400 hover:text-zinc-100"}"}>
              ➕ Add New Unit
            </.link>
            
            <.link navigate={~p"/admin/property"}
              class={"w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all #{if @current_tab == "manage_properties", do: "bg-blue-600 text-white shadow-lg shadow-blue-600/20", else: "hover:bg-zinc-800/70 text-zinc-400 hover:text-zinc-100"}"}>
              📋 View Your Houses
            </.link>

            <.link navigate={~p"/admin/bookings"}
              class={"w-full flex items-center justify-between px-4 py-3 rounded-xl text-sm font-medium transition-all #{if @current_tab == "bookings", do: "bg-blue-600 text-white shadow-lg shadow-blue-600/20", else: "hover:bg-zinc-800/70 text-zinc-400 hover:text-zinc-100"}"}>
              <span class="flex items-center gap-3">📅 Client Bookings</span>
              <span class="bg-zinc-950/60 text-blue-400 font-bold px-2 py-0.5 rounded-md text-[11px] border border-zinc-800"><%= length(@bookings) %></span>
            </.link>

            <div role="button" title="🚫 Coming Soon"
              class="w-full flex items-center justify-between px-4 py-3 rounded-xl text-sm font-medium transition-all text-zinc-500 bg-zinc-950/20 border border-zinc-900/50 cursor-not-allowed select-none">
              <span class="flex items-center gap-3">💬 Messages</span>
              <span class="bg-zinc-800 text-zinc-500 font-semibold px-1.5 py-0.5 rounded text-[10px]">Soon</span>
            </div>

            <.link navigate={~p"/admin/notifications"}
              class={"w-full flex items-center justify-between px-4 py-3 rounded-xl text-sm font-medium transition-all #{if @current_tab == "notifications", do: "bg-blue-600 text-white shadow-lg shadow-blue-600/20", else: "hover:bg-zinc-800/70 text-zinc-400 hover:text-zinc-100"}"}>
              <span class="flex items-center gap-3">🔔 Notifications</span>
              <span class="bg-zinc-800 text-blue-400 font-semibold px-1.5 py-0.5 rounded text-[10px]">Soon</span>
            </.link>
          </nav>
        </div>
      </aside>

      <main class="flex-1 flex flex-col lg:h-screen lg:overflow-y-auto">
        <header class="bg-zinc-900/40 border-b border-zinc-800 px-8 py-4 hidden lg:flex justify-between items-center">
          <h2 class="text-sm font-medium uppercase tracking-wider text-zinc-400"><%= @current_tab |> String.replace("_", " ") %> View</h2>
          <span class="text-xs font-semibold text-blue-400 bg-blue-500/10 border border-blue-500/20 px-3 py-1 rounded-full">Live Database Stack</span>
        </header>

        <div class="p-4 md:p-8 max-w-7xl w-full mx-auto">
          
          <%= if @current_tab == "add_property" do %>
            <div class="grid grid-cols-1 xl:grid-cols-12 gap-8 items-start">
              
              <div class="xl:col-span-7 bg-zinc-900/60 border border-zinc-800 p-5 md:p-6 rounded-2xl">
                <form multipart phx-change="change_form" phx-submit="save_property" class="space-y-5">
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">House Title</label>
                      <input type="text" name="property[title]" value={@form_data["title"]} placeholder="e.g., Sunrise Penthouse" required class="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-zinc-100 focus:border-blue-500 focus:outline-none" />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">Location</label>
                      <input type="text" name="property[location]" value={@form_data["location"]} placeholder="e.g., Kilimani, Nairobi" required class="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-zinc-100 focus:border-blue-500 focus:outline-none" />
                    </div>
                  </div>
                  <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">Night Price (KES)</label>
                      <input type="number" name="property[night_price]" value={@form_data["night_price"]} placeholder="4500" required class="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-zinc-100 focus:border-blue-500 focus:outline-none" />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">Day Price (KES)</label>
                      <input type="number" name="property[day_price]" value={@form_data["day_price"]} placeholder="2500" class="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-zinc-100 focus:border-blue-500 focus:outline-none" />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">Tier</label>
                      <select name="property[tier]" class="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-zinc-100 focus:border-blue-500 focus:outline-none">
                        <option value="Normal" selected={@form_data["tier"] == "Normal"}>Normal</option>
                        <option value="Medium" selected={@form_data["tier"] == "Medium"}>Medium</option>
                        <option value="Premium" selected={@form_data["tier"] == "Premium"}>Premium</option>
                      </select>
                    </div>
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-zinc-400 mb-2 uppercase tracking-wider">Included Perks</label>
                    <div class="grid grid-cols-3 gap-3">
                      <label class={"flex flex-col items-center justify-center p-3 rounded-xl border text-center cursor-pointer select-none #{if @form_data["wifi"] == "true", do: "border-blue-500 bg-blue-500/10 text-white", else: "border-zinc-800 bg-zinc-950/20 text-zinc-400"}"}>
                        <input type="checkbox" name="property[wifi]" value="true" checked={@form_data["wifi"] == "true"} class="hidden" />
                        <span class="text-sm">📶 WiFi</span>
                      </label>
                      <label class={"flex flex-col items-center justify-center p-3 rounded-xl border text-center cursor-pointer select-none #{if @form_data["tv"] == "true", do: "border-blue-500 bg-blue-500/10 text-white", else: "border-zinc-800 bg-zinc-950/20 text-zinc-400"}"}>
                        <input type="checkbox" name="property[tv]" value="true" checked={@form_data["tv"] == "true"} class="hidden" />
                        <span class="text-sm">📺 Smart TV</span>
                      </label>
                      <label class={"flex flex-col items-center justify-center p-3 rounded-xl border text-center cursor-pointer select-none #{if @form_data["music_system"] == "true", do: "border-blue-500 bg-blue-500/10 text-white", else: "border-zinc-800 bg-zinc-950/20 text-zinc-400"}"}>
                        <input type="checkbox" name="property[music_system]" value="true" checked={@form_data["music_system"] == "true"} class="hidden" />
                        <span class="text-sm">🔊 Sound</span>
                      </label>
                    </div>
                  </div>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">Status</label>
                      <select name="property[status]" class="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-zinc-100 focus:border-blue-500 focus:outline-none">
                        <option value="Available" selected={@form_data["status"] == "Available"}>Available</option>
                        <option value="Occupied" selected={@form_data["status"] == "Occupied"}>Occupied</option>
                        <option value="Maintenance" selected={@form_data["status"] == "Maintenance"}>Maintenance</option>
                      </select>
                    </div>
                    <%= if @form_data["status"] != "Available" do %>
                      <div>
                        <label class="block text-xs font-medium text-zinc-400 mb-1.5 uppercase tracking-wider">Unavailable Till</label>
                        <input type="date" name="property[unavailable_until]" value={@form_data["unavailable_until"]} class="w-full bg-zinc-950 border border-zinc-800 rounded-xl px-3.5 py-2.5 text-zinc-100 focus:border-blue-500 focus:outline-none" />
                      </div>
                    <% end %>
                  </div>
                  
                  <div>
                    <label class="block border border-dashed border-zinc-800 p-6 rounded-xl text-center bg-zinc-950/20 hover:border-zinc-700 transition-all cursor-pointer select-none" phx-drop-target={@uploads.property_images.ref}>
                      <.live_file_input upload={@uploads.property_images} style="display: none;" multiple />
                      <span class="text-xs font-semibold text-blue-400 block py-4">
                        📂 Click here or drag files to upload unit photos
                      </span>
                    </label>

                    <%= if Enum.any?(@uploads.property_images.entries) do %>
                      <div class="mt-4 space-y-2">
                        <label class="block text-[10px] font-bold text-zinc-500 uppercase tracking-wider px-0.5">
                          Staged Queue (<%= length(@uploads.property_images.entries) %>/5 entries)
                        </label>
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
                          <%= for entry <- @uploads.property_images.entries do %>
                            <div class="flex items-center gap-3 bg-zinc-950 p-2 rounded-xl border border-zinc-800">
                              <.live_img_preview entry={entry} class="w-12 h-12 object-cover rounded-lg flex-shrink-0 bg-zinc-900" />
                              <div class="flex-1 min-w-0">
                                <div class="text-xs font-medium text-zinc-300 truncate"><%= entry.client_name %></div>
                                <div class="w-full bg-zinc-800 h-1 rounded-full mt-1.5 overflow-hidden">
                                  <div class="bg-blue-500 h-full transition-all duration-300" style={"width: #{entry.progress}%"}></div>
                                </div>
                              </div>
                              <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} class="text-zinc-500 hover:text-red-400 p-1.5 transition-colors text-xs font-bold">
                                ✕
                              </button>
                            </div>
                          <% end %>
                        </div>
                        
                        <%= for err <- upload_errors(@uploads.property_images) do %>
                          <p class="text-xs text-red-400 bg-red-500/5 border border-red-500/10 p-2 rounded-lg mt-1">
                            ❌ Error: <%= Phoenix.Naming.humanize(err) %>
                          </p>
                        <% end %>
                      </div>
                    <% end %>
                  </div>

                  <button type="submit" class="w-full bg-blue-600 hover:bg-blue-500 py-3 rounded-xl font-medium transition-all">Commit Listing Into Production</button>
                </form>
              </div>

              <div class="xl:col-span-5 lg:sticky lg:top-6 space-y-4">
                <h3 class="text-xs font-bold uppercase tracking-widest text-zinc-500 flex items-center gap-2 px-1">
                  <span class="w-2 h-2 rounded-full bg-blue-500 animate-pulse"></span> Dynamic Card Preview
                </h3>
                <div class="bg-zinc-900 border border-zinc-800 rounded-3xl overflow-hidden shadow-2xl">
                  <div class="relative h-52 bg-zinc-950 flex items-center justify-center overflow-hidden">
                    <%= if Enum.any?(@uploads.property_images.entries) do %>
                      <%= for entry <- Enum.take(@uploads.property_images.entries, 1) do %>
                        <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                      <% end %>
                    <% else %>
                      <img src="https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600" class="w-full h-full object-cover opacity-40" />
                      <div class="absolute inset-0 flex items-center justify-center text-xs text-zinc-500 font-medium">Using Default Global Placeholder</div>
                    <% end %>
                    
                    <div class="absolute top-4 left-4 flex gap-1.5">
                      <span class="bg-zinc-900/90 text-zinc-300 text-[10px] font-bold tracking-wider uppercase px-2 py-0.5 rounded-md border border-zinc-800">
                        <%= @form_data["tier"] %>
                      </span>
                      <span class={"text-[10px] font-bold tracking-wider uppercase px-2 py-0.5 rounded-md border #{if @form_data["status"] == "Available", do: "bg-green-500/20 border-green-500/30 text-green-400", else: "bg-amber-500/20 border-amber-500/30 text-amber-400"}"}>
                        <%= @form_data["status"] %>
                      </span>
                    </div>
                    <div class="absolute top-4 right-4 bg-zinc-900/90 text-xs font-semibold px-2.5 py-1 rounded-full border border-zinc-800">
                      KES <%= @form_data["night_price"] |> fill_blank("0") %>/night
                    </div>
                  </div>
                  
                  <%= if length(@uploads.property_images.entries) > 1 do %>
                    <div class="p-3 bg-zinc-950/60 border-b border-zinc-800 flex gap-2 overflow-x-auto">
                      <%= for entry <- Enum.drop(@uploads.property_images.entries, 1) do %>
                        <div class="w-12 h-12 rounded-lg overflow-hidden border border-zinc-800 flex-shrink-0">
                          <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                        </div>
                      <% end %>
                    </div>
                  <% end %>

                  <div class="p-5 space-y-4">
                    <div>
                      <h4 class="text-xl font-bold text-white truncate"><%= @form_data["title"] |> fill_blank("Untitled Property") %></h4>
                      <p class="text-zinc-400 text-sm mt-1">📍 <%= @form_data["location"] |> fill_blank("Location unassigned") %></p>
                    </div>
                    <div class="flex flex-wrap gap-1.5">
                      <%= if @form_data["wifi"] == "true" do %><span class="bg-zinc-950 text-zinc-400 text-[10px] px-2 py-1 rounded-md border border-zinc-800">📶 WiFi</span><% end %>
                      <%= if @form_data["tv"] == "true" do %><span class="bg-zinc-950 text-zinc-400 text-[10px] px-2 py-1 rounded-md border border-zinc-800">📺 Smart TV</span><% end %>
                      <%= if @form_data["music_system"] == "true" do %><span class="bg-zinc-950 text-zinc-400 text-[10px] px-2 py-1 rounded-md border border-zinc-800">🔊 Sound System</span><% end %>
                    </div>
                    <div class="text-[11px] text-zinc-500 pt-3 border-t border-zinc-800/60">
                      Day stay fee: <span class="text-zinc-200">KES <%= @form_data["day_price"] |> fill_blank("0") %></span>
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
                      <% else %>
                        <div class="w-full h-full bg-zinc-900 flex items-center justify-center text-xs text-zinc-600">No Image Attached</div>
                      <% end %>
                      <span class="absolute top-3 left-3 bg-zinc-900/90 border border-zinc-800 text-[10px] px-2 py-0.5 rounded text-zinc-300 uppercase font-semibold">
                        <%= property.status %>
                      </span>
                    </div>
                    <div class="p-4 space-y-2">
                      <h4 class="text-base font-bold text-white"><%= property.title %></h4>
                      <p class="text-xs text-zinc-500">📍 <%= property.location %> • <span class="text-blue-400"><%= property.tier %></span></p>
                      
                      <div class="flex gap-1 pt-1">
                        <%= if property.wifi do %><span class="text-[10px] bg-zinc-950 px-1.5 py-0.5 rounded border border-zinc-800 text-zinc-400">📶 WiFi</span><% end %>
                        <%= if property.tv do %><span class="text-[10px] bg-zinc-950 px-1.5 py-0.5 rounded border border-zinc-800 text-zinc-400">📺 TV</span><% end %>
                        <%= if property.music_system do %><span class="text-[10px] bg-zinc-950 px-1.5 py-0.5 rounded border border-zinc-800 text-zinc-400">🔊 Sound</span><% end %>
                      </div>

                      <div class="text-xs text-zinc-400 pt-2 border-t border-zinc-800/60">
                        Nightly: <strong>KES <%= property.night_price %></strong> | Day: <strong>KES <%= property.day_price %></strong>
                      </div>
                      <%= if property.unavailable_until do %>
                        <div class="text-[10px] text-amber-400 bg-amber-500/5 p-1 rounded border border-amber-500/10 mt-1">
                          📅 Blocked till: <%= property.unavailable_until %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                  <div class="p-4 pt-0 flex justify-end">
                    <button phx-click="delete_property" phx-value-id={property.id} class="text-xs text-red-400 hover:underline" data-confirm="Delete permanently?">Remove</button>
                  </div>
                </div>
              <% end %>
            </div>
            <%= if @properties == [] do %>
              <div class="text-center py-16 text-zinc-600 text-sm">No properties found in your database.</div>
            <% end %>
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
                    <th class="p-4">Metrics</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-zinc-800/50">
                  <%= for booking <- @bookings do %>
                    <tr class="hover:bg-zinc-900/20 transition-all">
                      <td class="p-4">
                        <div class="font-medium text-white"><%= booking.client_name %></div>
                        <div class="text-xs text-zinc-500"><%= booking.client_phone %></div>
                      </td>
                      <td class="p-4 font-medium text-zinc-300"><%= booking.property.title %></td>
                      <td class="p-4 text-xs text-zinc-400">📅 <%= booking.check_in %> to <%= booking.check_out %></td>
                      <td class="p-4 font-semibold text-white">KES <%= booking.total_price %></td>
                      <td class="p-4">
                        <span class="bg-blue-500/10 border border-blue-500/20 text-blue-400 px-2.5 py-0.5 rounded-full text-xs font-medium">
                          <%= booking.status %>
                        </span>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
              <%= if @bookings == [] do %>
                <div class="text-center py-12 text-zinc-600 text-xs">No active clients found in database.</div>
              <% end %>
            </div>
          <% end %>

          <%= if @current_tab in ["messages", "notifications"] do %>
            <div class="text-center py-16 bg-zinc-900/40 border border-zinc-800 rounded-2xl text-zinc-500 text-sm">
              The <%= @current_tab %> view panel is ready to be linked to your communication modules.
            </div>
          <% end %>

        </div>
      </main>
    </div>
    """
  end

  # --- Private Cloudinary Direct Upload Engine ---
  defp upload_to_cloudinary(local_path) do
    config = Application.get_env(:home, :cloudinary)
    cloud_name = config[:cloud_name]
    api_key = config[:api_key]
    api_secret = config[:api_secret]
    
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    
    # Generate alphabetical parameter string signature
    signature_string = "timestamp=#{timestamp}#{api_secret}"
    signature = :crypto.hash(:sha, signature_string) |> Base.encode16(case: :lower)
    
    url = "https://api.cloudinary.com/v1_1/#{cloud_name}/image/upload"
    boundary = "----PhoenixLiveViewUploadBoundary#{timestamp}"
    
    url_cl = String.to_charlist(url)
    content_type_cl = String.to_charlist("multipart/form-data; boundary=#{boundary}")
    headers_cl = [{"connection", "close"}]
    
    # Read raw binary without enforcing string interpolation rules
    {:ok, file_binary} = File.read(local_path)
    
    # Pack parameters inside iodata to avoid internal string conversion crashes
    body = [
      "--#{boundary}\r\nContent-Disposition: form-data; name=\"api_key\"\r\n\r\n#{api_key}\r\n",
      "--#{boundary}\r\nContent-Disposition: form-data; name=\"timestamp\"\r\n\r\n#{timestamp}\r\n",
      "--#{boundary}\r\nContent-Disposition: form-data; name=\"signature\"\r\n\r\n#{signature}\r\n",
      "--#{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"upload.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n",
      file_binary,
      "\r\n--#{boundary}--\r\n"
    ]

    case :httpc.request(:post, {url_cl, headers_cl, content_type_cl, body}, [], []) do
      {:ok, {{_, 200, _}, _headers, response_body}} ->
        {:ok, json} = Jason.decode(response_body)
        {:ok, Map.get(json, "secure_url")}
      {:ok, {{_, status_code, _}, _, response_body}} ->
        {:error, "Cloudinary error status #{status_code}: #{response_body}"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp default_form_data do
    %{
      "title" => "", "location" => "", "night_price" => "", "day_price" => "", 
      "tier" => "Normal", "wifi" => "false", "tv" => "false", "music_system" => "false",
      "status" => "Available", "unavailable_until" => ""
    }
  end

  defp fill_blank(val, fallback) do
    if is_nil(val) || String.trim(val) == "", do: fallback, else: val
  end
end