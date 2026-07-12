defmodule HomeWeb.TestLive do
  use HomeWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Add to Digital Menu")
      |> assign(:category, "Food")
      |> assign(:name, "")
      |> assign(:price, "")
      |> assign(:description, "")
      |> assign(:status, "Available")
      |> assign(:variations, [])
      |> assign(:var_type, "")
      |> assign(:var_price, "")
      |> assign(:sidebar_open, false)
      |> assign(:success, false)
      |> assign(:pathname, "/staff")
      |> allow_upload(:image, accept: ~w(.jpg .jpeg .png .webp), max_entries: 1)

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  @impl true
  def handle_event("set_category", %{"category" => category}, socket) do
    variations = if category == "Food", do: [], else: socket.assigns.variations
    {:noreply, assign(socket, category: category, variations: variations)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"name" => name, "price" => price, "description" => description, "status" => status},
        socket
      ) do
    {:noreply, assign(socket, name: name, price: price, description: description, status: status)}
  end

  @impl true
  def handle_event("validate_variation", %{"var_type" => type, "var_price" => price}, socket) do
    {:noreply, assign(socket, var_type: type, var_price: price)}
  end

  @impl true
  def handle_event("add_variation", _, socket) do
    type = socket.assigns.var_type
    price = socket.assigns.var_price

    if type != "" and price != "" do
      new_variation = %{type: type, price: String.to_integer(price)}

      {:noreply,
       assign(socket,
         variations: socket.assigns.variations ++ [new_variation],
         var_type: "",
         var_price: ""
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("remove_variation", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    {:noreply, assign(socket, variations: List.delete_at(socket.assigns.variations, index))}
  end

  @impl true
  def handle_event("save", _params, socket) do
    has_image = Enum.any?(socket.uploads.image.entries)

    if socket.assigns.name == "" or socket.assigns.description == "" or not has_image do
      {:noreply, put_flash(socket, :error, "Please provide a Name, Description, and Image.")}
    else
      base_price =
        case Integer.parse(socket.assigns.price) do
          {num, _} -> num
          :error -> 0
        end

      final_price =
        if socket.assigns.category == "Food" do
          base_price
        else
          case socket.assigns.variations do
            [first | _] -> first.price
            [] -> base_price
          end
        end

      if final_price <= 0 do
        {:noreply, put_flash(socket, :error, "Please set a valid price.")}
      else
        [image_url] =
          consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
            {:ok, "/uploads/#{Path.basename(path)}"}
          end)

        _payload = %{
          name: socket.assigns.name,
          category: socket.assigns.category,
          price: final_price,
          description: socket.assigns.description,
          status: socket.assigns.status,
          image_url: image_url,
          variations:
            if(socket.assigns.category != "Food", do: socket.assigns.variations, else: [])
        }

        Process.send_after(self(), :clear_success, 3000)

        {:noreply,
         socket
         |> assign(name: "", price: "", description: "", status: "Available", variations: [])
         |> assign(:success, true)}
      end
    end
  end

  @impl true
  def handle_info(:clear_success, socket) do
    {:noreply, assign(socket, :success, false)}
  end

  # --- Internal UI Components & CSS Render Template ---

  attr :status, :string, required: true

  def status_badge(assigns) do
    ~H"""
    <span class={"status-badge badge-#{@status |> String.downcase() |> String.replace(" ", "-")}"}>
      {@status}
    </span>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <style>
      :root {
        --primary-gradient: linear-gradient(135deg, #ea580c, #dc2626);
        --text-orange: #ea580c;
        --bg-slate-50: #f8fafc;
        --border-slate-200: #e2e8f0;
        --text-slate-900: #0f172a;
        --text-slate-500: #64748b;
        --text-slate-400: #94a3b8;
      }

      .app-layout {
        display: flex;
        min-height: 100vh;
        background-color: var(--bg-slate-50);
        font-family: system-ui, -apple-system, sans-serif;
        color: var(--text-slate-900);
      }

      .desktop-sidebar {
        width: 16rem;
        background: #ffffff;
        border-right: 1px solid var(--border-slate-200);
        display: flex;
        flex-direction: column;
        position: sticky;
        top: 0;
        height: 100vh;
      }

      @media (max-width: 768px) {
        .desktop-sidebar { display: none; }
      }

      .panel-header {
        padding: 1.5rem;
        text-align: center;
      }

      .brand-title {
        font-size: 1.25rem;
        font-weight: 800;
        background: var(--primary-gradient);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        margin: 0;
      }

      .panel-subtitle {
        font-size: 10px;
        color: var(--text-slate-500);
        font-weight: 700;
        letter-spacing: 0.2em;
        text-transform: uppercase;
        margin-top: 0.25rem;
      }

      .nav-container {
        flex: 1;
        padding: 0 1rem;
      }

      .nav-link {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        padding: 0.75rem 1rem;
        border-radius: 0.75rem;
        font-weight: 600;
        text-decoration: none;
        color: #475569;
        margin-bottom: 0.25rem;
        transition: all 0.2s;
      }

      .nav-link:hover { background-color: #f1f5f9; }
      .nav-link.active { background-color: #fff7ed; color: var(--text-orange); }

      .main-wrapper {
        flex: 1;
        min-width: 0;
        display: flex;
        flex-direction: column;
      }

      .mobile-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0.75rem 1rem;
        background: rgba(255, 255, 255, 0.95);
        border-b: 1px solid var(--border-slate-200);
        backdrop-filter: blur(4px);
        position: sticky;
        top: 0;
        z-index: 30;
      }

      @media (min-width: 769px) {
        .mobile-header { display: none; }
      }

      .menu-btn {
        height: 2.75rem;
        width: 2.75rem;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 0.75rem;
        border: 1px solid var(--border-slate-200);
        background: white;
        cursor: pointer;
      }

      .content-body {
        flex: 1;
        padding: 2rem;
      }

      @media (max-width: 640px) {
        .content-body { padding: 1rem; }
      }

      .page-header-block {
        display: flex;
        flex-direction: column;
        gap: 1rem;
        margin-bottom: 2rem;
      }

      @media (min-width: 640px) {
        .page-header-block {
          flex-direction: row;
          justify-content: space-between;
          align-items: flex-end;
        }
      }

      .success-toast {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        color: #10b981;
        background: #ecfdf5;
        padding: 0.5rem 1rem;
        border-radius: 0.5rem;
        border: 1px solid #d1fae5;
        font-weight: 500;
        font-size: 0.875rem;
      }

      .tabs-bar {
        display: flex;
        gap: 0.5rem;
        overflow-x: auto;
        background: rgba(226, 232, 240, 0.5);
        padding: 0.375rem;
        border-radius: 1rem;
        border: 1px solid var(--border-slate-200);
        width: max-content;
        margin-bottom: 2rem;
      }

      .tab-btn {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.5rem 1.25rem;
        border-radius: 0.75rem;
        font-weight: 700;
        font-size: 0.875rem;
        border: none;
        background: transparent;
        color: var(--text-slate-500);
        cursor: pointer;
        transition: all 0.2s;
      }

      .tab-btn.active {
        background: white;
        color: var(--text-orange);
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
      }

      .grid-layout {
        display: grid;
        grid-template-columns: 1fr;
        gap: 2rem;
      }

      @media (min-width: 1024px) {
        .grid-layout { grid-template-columns: 2fr 1fr; }
      }

      .form-card {
        background: white;
        border-radius: 1.5rem;
        border: 1px solid var(--border-slate-200);
        padding: 2rem;
      }

      .form-grid {
        display: grid;
        grid-template-columns: 1fr;
        gap: 1.5rem;
        margin-bottom: 1.5rem;
      }

      @media (min-width: 640px) {
        .form-grid { grid-template-columns: 1fr 1fr; }
      }

      .input-wrapper {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
      }

      .field-label {
        font-size: 0.75rem;
        font-weight: 900;
        text-transform: uppercase;
        color: var(--text-slate-400);
        letter-spacing: 0.1em;
      }

      .styled-input, .styled-textarea, .styled-select {
        width: 100%;
        padding: 0.75rem 1rem;
        border-radius: 0.75rem;
        background: var(--bg-slate-50);
        border: 1px solid transparent;
        font-weight: 500;
        outline: none;
        box-sizing: border-box;
      }

      .styled-input:focus, .styled-textarea:focus {
        border-color: var(--text-orange);
        background: white;
      }

      .price-input-container {
        position: relative;
      }

      .currency-prefix {
        position: absolute;
        left: 1rem;
        top: 50%;
        transform: translateY(-50%);
        color: var(--text-slate-400);
        font-weight: 700;
        font-size: 0.875rem;
      }

      .price-input-container .styled-input {
        padding-left: 3.5rem;
      }

      .variations-box {
        background: #fff7ed;
        border: 1px solid #ffedd5;
        padding: 1.25rem;
        border-radius: 1rem;
        display: flex;
        flex-direction: column;
        gap: 1rem;
      }

      .variation-entry-row {
        display: grid;
        grid-template-columns: 1fr;
        gap: 0.5rem;
      }

      @media (min-width: 640px) {
        .variation-entry-row { grid-template-columns: 1fr 7rem auto; }
      }

      .add-var-btn {
        background: var(--text-orange);
        color: white;
        border: none;
        border-radius: 0.75rem;
        padding: 0 1rem;
        height: 2.5rem;
        cursor: pointer;
        font-weight: bold;
      }

      .chips-container {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
      }

      .var-chip {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        background: white;
        border: 1px solid #fed7aa;
        padding: 0.375rem 0.75rem;
        border-radius: 9999px;
        font-size: 0.75rem;
        font-weight: 700;
        color: #c2410c;
      }

      .remove-chip-btn {
        background: transparent;
        border: none;
        color: #fdba74;
        cursor: pointer;
        font-size: 0.875rem;
      }

      .remove-chip-btn:hover { color: #dc2626; }

      .file-dropzone {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 100%;
        padding: 0.75rem 1rem;
        border-radius: 0.75rem;
        border: 2px dashed var(--border-slate-200);
        background: var(--bg-slate-50);
        cursor: pointer;
        box-sizing: border-box;
      }

      .file-dropzone:hover { border-color: var(--text-orange); }

      .submit-btn {
        width: 100%;
        background: #0f172a;
        color: white;
        font-weight: 900;
        text-transform: uppercase;
        letter-spacing: 0.1em;
        padding: 1.25rem;
        border-radius: 1rem;
        border: none;
        cursor: pointer;
        box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1);
        transition: transform 0.1s;
      }

      .submit-btn:active { transform: scale(0.98); }

      .preview-pane-sticky {
        position: sticky;
        top: 2rem;
        height: fit-content;
      }

      .preview-card {
        background: white;
        border-radius: 2.5rem;
        overflow: hidden;
        border: 1px solid var(--border-slate-200);
        box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
      }

      .preview-image-box {
        position: relative;
        height: 16rem;
        background: #f1f5f9;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: var(--text-slate-400);
      }

      .preview-image-box img {
        width: 100%;
        height: 100%;
        object-fit: cover;
      }

      .badge-container {
        position: absolute;
        top: 1.25rem;
        right: 1.25rem;
        transform: scale(1.1);
      }

      .status-badge {
        padding: 0.125rem 0.625rem;
        border-radius: 9999px;
        font-size: 0.75rem;
        font-weight: 500;
        border: 1px solid;
      }

      .badge-available { background: #ecfdf5; color: #047857; border-color: #a7f3d0; }
      .badge-pending { background: #fffbeb; color: #b45309; border-color: #fde68a; }
      .badge-not-available { background: #fff5f5; color: #b91c1c; border-color: #fecaca; }

      .preview-details {
        padding: 2rem;
      }

      .preview-title {
        font-size: 1.5rem;
        font-weight: 900;
        font-style: italic;
        text-transform: uppercase;
        letter-spacing: -0.05em;
        margin: 0;
      }

      .preview-price {
        color: var(--text-orange);
        font-weight: 900;
        font-size: 1.5rem;
        margin: 0.25rem 0 0 0;
        letter-spacing: -0.05em;
      }

      .preview-desc {
        color: var(--text-slate-500);
        font-size: 0.875rem;
        margin-top: 1rem;
        line-height: 1.6;
      }

      .preview-footer {
        margin-top: 2rem;
        padding-top: 1.5rem;
        border-top: 1px solid #f1f5f9;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }

      .category-tag {
        font-size: 10px;
        font-weight: 900;
        color: var(--text-orange);
        background: #fff7ed;
        padding: 0.375rem 0.75rem;
        border-radius: 9999px;
        text-transform: uppercase;
        letter-spacing: 0.1em;
      }

      .circle-plus-icon {
        width: 2.5rem;
        height: 2.5rem;
        border-radius: 9999px;
        background: #0f172a;
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.25rem;
      }

      .mobile-drawer-overlay {
        position: fixed;
        inset: 0;
        z-index: 50;
      }
      .drawer-bg-blur {
        position: absolute;
        inset: 0;
        background: rgba(15, 23, 42, 0.45);
        border: none;
        width: 100%;
        height: 100%;
      }
      .drawer-content {
        position: relative;
        display: flex;
        flex-direction: column;
        height: 100%;
        width: 19rem;
        max-width: 85vw;
        background: white;
        box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
      }
      .drawer-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 1.25rem;
      }
    </style>

    <div class="app-layout">
      <aside class="desktop-sidebar">
        <div class="panel-header">
          <h1 class="brand-title">African Cuisine</h1>
          <p class="panel-subtitle">Staff Panel</p>
        </div>
        <.staff_nav variant="sidebar" pathname={@pathname} />
      </aside>

      <div class="main-wrapper">
        <header class="mobile-header">
          <div>
            <h1 class="brand-title" style="font-size: 1rem;">African Cuisine</h1>
            <p class="panel-subtitle" style="font-size: 9px; letter-spacing: 0.18em;">Staff Panel</p>
          </div>
          <button type="button" phx-click="toggle_sidebar" class="menu-btn">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="1.5"
              stroke="currentColor"
              style="width: 1.5rem; height: 1.5rem;"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
              />
            </svg>
          </button>
        </header>

        <.staff_nav variant="mobile" pathname={@pathname} />

        <%= if @sidebar_open do %>
          <div class="mobile-drawer-overlay" role="dialog" aria-modal="true">
            <button type="button" phx-click="toggle_sidebar" class="drawer-bg-blur"></button>
            <aside class="drawer-content">
              <div class="drawer-header">
                <div>
                  <h1 class="brand-title" style="font-size: 1.125rem;">African Cuisine</h1>
                  <p class="panel-subtitle">Staff Panel</p>
                </div>
                <button
                  type="button"
                  phx-click="toggle_sidebar"
                  class="menu-btn"
                  style="height:2.5rem; width:2.5rem; background:#f1f5f9; border:none;"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    style="width: 1.25rem; height: 1.25rem;"
                  >
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <.staff_nav variant="sidebar" pathname={@pathname} phx-click="toggle_sidebar" />
            </aside>
          </div>
        <% end %>

        <main class="content-body">
          <div style="max-width: 64rem; margin: 0 auto;">
            <div class="page-header-block">
              <div>
                <h2 style="font-size: 1.75rem; font-weight: 800; color: #1e293b; margin: 0;">
                  {@page_title}
                </h2>
                <p style="color: var(--text-slate-500); margin: 0.25rem 0 0 0;">
                  Configure item details for customers to see.
                </p>
              </div>
              <%= if @success do %>
                <div class="success-toast">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="2"
                    stroke="currentColor"
                    style="width: 1.25rem; height: 1.25rem;"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <span>Item Published!</span>
                </div>
              <% end %>
            </div>

            <div class="tabs-bar">
              <%= for {cat_id, emoji} <- [{"Food", "🍕"}, {"Drinks", "🍺"}, {"Fruits", "🍎"}, {"Others", "🥞"}] do %>
                <button
                  type="button"
                  phx-click="set_category"
                  phx-value-category={cat_id}
                  class={"tab-btn #{if @category == cat_id, do: "active"}"}
                >
                  <span><%= emoji %></span>{cat_id}
                </button>
              <% end %>
            </div>

            <div class="grid-layout">
              <div class="form-card">
                <form
                  phx-change="validate"
                  phx-submit="save"
                  class="space-y-6"
                  style="display: flex; flex-direction: column; gap: 1.5rem;"
                >
                  <div class="form-grid">
                    <div class="input-wrapper">
                      <label class="field-label">{@category} Name</label>
                      <input
                        type="text"
                        name="name"
                        value={@name}
                        class="styled-input"
                        placeholder={"e.g. #{if @category == "Drinks", do: "Soda", else: "Mbuzi Choma"}"}
                      />
                    </div>
                    <div class="input-wrapper">
                      <label class="field-label">Base Price (KSh)</label>
                      <div class="price-input-container">
                        <span class="currency-prefix">KES</span>
                        <input
                          type="number"
                          name="price"
                          value={@price}
                          class="styled-input"
                          placeholder="0.00"
                        />
                      </div>
                    </div>
                  </div>

                  <%= if @category != "Food" do %>
                    <div class="variations-box">
                      <div style="display: flex; justify-content: space-between; align-items: center;">
                        <label class="field-label" style="color: #9a3412;">Sizes / Variations</label>
                        <span style="font-size: 10px; color: #fb923c; font-weight: 700; font-style: italic; text-transform: uppercase;">
                          Recommended for drinks
                        </span>
                      </div>
                      <div class="variation-entry-row" phx-change="validate_variation">
                        <input
                          type="text"
                          name="var_type"
                          value={@var_type}
                          placeholder="e.g. 500ml"
                          class="styled-input"
                          style="background: white; border: 1px solid var(--border-slate-200);"
                        />
                        <input
                          type="number"
                          name="var_price"
                          value={@var_price}
                          placeholder="Price"
                          class="styled-input"
                          style="background: white; border: 1px solid var(--border-slate-200);"
                        />
                        <button type="button" phx-click="add_variation" class="add-var-btn">➕</button>
                      </div>
                      <div class="chips-container">
                        <%= for {v, i} <- Enum.with_index(@variations) do %>
                          <div class="var-chip">
                            {v.type}: {v.price}/-
                            <button
                              type="button"
                              phx-click="remove_variation"
                              phx-value-index={i}
                              class="remove-chip-btn"
                            >
                              ✕
                            </button>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>

                  <div class="input-wrapper">
                    <label class="field-label">Description</label>
                    <textarea
                      rows="4"
                      name="description"
                      class="styled-textarea"
                      placeholder="Short description for the customer..."
                    ><%= @description %></textarea>
                  </div>

                  <div class="form-grid">
                    <div class="input-wrapper">
                      <label class="field-label">Availability Status</label>
                      <select
                        name="status"
                        class="styled-select"
                        style="-webkit-appearance: none; font-weight: bold; color: #334155;"
                      >
                        <option value="Available" selected={@status == "Available"}>
                          Available Now
                        </option>
                        <option value="Pending" selected={@status == "Pending"}>
                          Pending / Out of Stock
                        </option>
                        <option value="Not Available" selected={@status == "Not Available"}>
                          Not Available
                        </option>
                      </select>
                    </div>
                    <div class="input-wrapper">
                      <label class="field-label">Item Image</label>
                      <label class="file-dropzone" phx-drop-target={@uploads.image.ref}>
                        <span style="font-size: 0.75rem; font-weight: 700; text-transform: uppercase; letter-spacing: -0.01em;">
                          {if Enum.any?(@uploads.image.entries),
                            do: "Image Ready 📸",
                            else: "Select Photo 📤"}
                        </span>
                        <.live_file_input upload={@uploads.image} style="display: none;" />
                      </label>
                    </div>
                  </div>

                  <button type="submit" class="submit-btn">
                    Add to {@category} Section
                  </button>
                </form>
              </div>

              <div class="preview-pane-sticky">
                <h3 class="field-label" style="margin: 0 0 1rem 0.5rem;">Customer Preview</h3>
                <div class="preview-card">
                  <div class="preview-image-box">
                    <%= if Enum.any?(@uploads.image.entries) do %>
                      <%= for entry <- @uploads.image.entries do %>
                        <.live_img_preview entry={entry} />
                      <% end %>
                    <% else %>
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="1"
                        stroke="currentColor"
                        style="width: 3rem; height: 3rem;"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375 0 11-.75 0 .375 0 010 .75z"
                        />
                      </svg>
                      <p style="font-size: 10px; font-weight: 900; text-transform: uppercase; letter-spacing: 0.1em; margin: 0.5rem 0 0 0;">
                        No Image Linked
                      </p>
                    <% end %>
                    <div class="badge-container"><.status_badge status={@status} /></div>
                  </div>
                  <div class="preview-details">
                    <h4 class="preview-title">{if @name == "", do: "New Item", else: @name}</h4>

                    <%= if @category != "Food" and length(@variations) > 0 do %>
                      <% first_var = List.first(@variations) %>
                      <div style="margin-top: 0.75rem;">
                        <div style="font-size: 0.75rem; font-weight: 900; border: 2px solid #f1f5f9; border-radius: 0.5rem; padding: 0.5rem 0.75rem; background: var(--bg-slate-50); color: var(--text-orange); width: fit-content;">
                          {first_var.type} — KSh {first_var.price}
                        </div>
                      </div>
                    <% else %>
                      <p class="preview-price">KSh {if @price == "", do: "0.00", else: @price}</p>
                    <% end %>

                    <p class="preview-desc">
                      {if @description == "",
                        do: "Product details will appear here for the customer.",
                        else: @description}
                    </p>
                    <div class="preview-footer">
                      <span class="category-tag">{@category}</span>
                      <div class="circle-plus-icon">＋</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
    """
  end

  defp staff_nav(assigns) do
    ~H"""
    <nav
      class={if @variant == "mobile", do: "tabs-bar", else: "nav-container"}
      style={
        if @variant == "mobile",
          do: "margin: 0.75rem 1rem; width: auto; max-width: calc(100vw - 2rem);",
          else: ""
      }
    >
      <% items = [
        {"/staff", "Add New Item"},
        {"/staff/inventory", "Menu Inventory"},
        {"/staff/orders", "Live Orders"}
      ] %>
      <%= for {href, label} <- items do %>
        <a
          href={href}
          class={"nav-link #{if @pathname == href, do: "active"}"}
          style={
            if @variant == "mobile",
              do:
                "padding: 0.5rem 0.75rem; font-size: 0.75rem; margin-bottom: 0; white-space: nowrap;",
              else: ""
          }
        >
          <span>{label}</span>
        </a>
      <% end %>
    </nav>
    """
  end
end
